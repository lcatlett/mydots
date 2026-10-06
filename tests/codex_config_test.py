import base64
import contextlib
import hashlib
import hmac
import importlib.machinery
import importlib.util
import io
import json
import os
import random
import stat
import string
import subprocess
import sys
import tempfile
import unittest
from collections.abc import Callable
from pathlib import Path
from unittest import mock

import tomllib

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "bin" / "codex-config"
FIXTURES = ROOT / "tests" / "fixtures" / "codex-config"
POLICY = FIXTURES / "policy.toml"

ALNUM = string.ascii_letters + string.digits
UPPER_DIGITS = string.ascii_uppercase + string.digits

# Shapes the detector and the gitleaks default rules know. Each token is
# SYNTHETIC, generated per run from a seeded generator, so the repository
# never holds a secret-shaped literal for gitleaks to flag.
TOKEN_SHAPES: dict[str, Callable[[Callable[[str, int], str]], str]] = {
    "github": lambda pick: "ghp_" + pick(ALNUM, 36),
    "github-fine-grained": lambda pick: (
        "github_pat_" + pick(ALNUM, 22) + "_" + pick(ALNUM, 59)
    ),
    "openai": lambda pick: "sk-proj-" + pick(ALNUM + "-_", 48),
    "anthropic": lambda pick: "sk-ant-api03-" + pick(ALNUM + "-_", 93) + "AA",
    "google": lambda pick: "AIza" + pick(ALNUM + "-_", 35),
    "slack-bot": lambda pick: (
        f"xoxb-{pick(string.digits, 12)}-{pick(string.digits, 13)}-{pick(ALNUM, 24)}"
    ),
    "slack-app": lambda pick: (
        f"xapp-1-{pick(UPPER_DIGITS, 11)}-{pick(string.digits, 13)}-{pick(ALNUM, 64)}"
    ),
    "slack-webhook": lambda pick: (
        f"https://hooks.slack.com/services/T{pick(UPPER_DIGITS, 8)}"
        f"/B{pick(UPPER_DIGITS, 8)}/{pick(ALNUM, 24)}"
    ),
    "aws-access-key": lambda pick: "AKIA" + pick(UPPER_DIGITS, 16),
    "aws-secret-key": lambda pick: pick(ALNUM + "+/", 40),
    "generic-high-entropy": lambda pick: pick(ALNUM, 32),
    "bearer": lambda pick: "Bearer " + pick(ALNUM + "-._~", 40),
    "jwt": lambda pick: (
        "eyJ" + pick(ALNUM, 33) + ".eyJ" + pick(ALNUM, 60) + "." + pick(ALNUM, 43)
    ),
    "private-key": lambda pick: (
        "-----BEGIN PRIVATE KEY-----\n"
        + pick(ALNUM, 64)
        + "\n-----END PRIVATE KEY-----"
    ),
}


def synthetic_token(kind: str) -> str:
    rng = random.Random(f"synthetic-{kind}")
    return TOKEN_SHAPES[kind](
        lambda alphabet, length: "".join(rng.choice(alphabet) for _ in range(length))
    )


def leaked_fragments(token: str, output: str, surroundings: str = "") -> set[str]:
    """Eight-character pieces of token in output, other than ones the
    non-secret text around the token (a URL scheme, say) also holds."""
    pieces = {token[i : i + 8] for i in range(len(token) - 7)}
    return {piece for piece in pieces if piece in output and piece not in surroundings}


def load_codex_config():
    loader = importlib.machinery.SourceFileLoader("codex_config", str(SCRIPT))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    sys.modules[loader.name] = module  # dataclasses resolve types through it
    with mock.patch.object(sys, "dont_write_bytecode", True):  # keep bin/ clean
        loader.exec_module(module)
    return module


CODEX_CONFIG = load_codex_config()


def run_in_process(*argv: str, stdin: str = "") -> tuple[int, str]:
    stdout, stderr = io.StringIO(), io.StringIO()
    with (
        contextlib.redirect_stdout(stdout),
        contextlib.redirect_stderr(stderr),
        mock.patch("sys.stdin", io.StringIO(stdin)),
    ):
        args = CODEX_CONFIG.build_parser().parse_args(argv)
        code = args.handler(args)
    return code, stdout.getvalue() + stderr.getvalue()


class CodexConfigCliTest(unittest.TestCase):
    def run_cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

    def check_fixture(self, name: str) -> subprocess.CompletedProcess[str]:
        return self.run_cli(
            "check",
            "--config",
            str(FIXTURES / name),
            "--policy",
            str(POLICY),
        )

    def test_check_accepts_approved_literal_and_secret_variable_references(
        self,
    ) -> None:
        result = self.check_fixture("valid.toml")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Codex MCP policy: PASS", result.stdout)

    def test_check_rejects_literal_interpolation_without_printing_value(self) -> None:
        result = self.check_fixture("interpolation.toml")

        self.assertEqual(result.returncode, 1)
        self.assertIn("mcp_servers.pal.env.LOG_LEVEL", result.stderr)
        self.assertNotIn("${LOG_LEVEL}", result.stderr)

    def test_check_rejects_dollar_variable_without_printing_value(self) -> None:
        result = self.check_fixture("dollar-variable.toml")

        self.assertEqual(result.returncode, 1)
        self.assertIn("mcp_servers.pal.env.LOG_LEVEL", result.stderr)
        self.assertNotIn("$LOG_LEVEL", result.stderr)

    def test_check_rejects_plaintext_secret_without_printing_value(self) -> None:
        result = self.check_fixture("plaintext-secret.toml")

        self.assertEqual(result.returncode, 1)
        self.assertIn("mcp_servers.pal.env.OPENAI_API_KEY", result.stderr)
        self.assertNotIn("literal-secret-material", result.stderr)

    def test_check_rejects_unapproved_literal_env_key(self) -> None:
        result = self.check_fixture("unapproved-literal.toml")

        self.assertEqual(result.returncode, 1)
        self.assertIn("mcp_servers.pal.env.DEBUG", result.stderr)

    def test_check_rejects_unapproved_secret_variable_for_server(self) -> None:
        result = self.check_fixture("unapproved-secret-var.toml")

        self.assertEqual(result.returncode, 1)
        self.assertIn("mcp_servers.pal.env_vars", result.stderr)
        self.assertIn("AWS_SECRET_ACCESS_KEY", result.stderr)

    def test_check_rejects_literal_authorization_header_without_printing_value(
        self,
    ) -> None:
        result = self.check_fixture("literal-auth-header.toml")

        self.assertEqual(result.returncode, 1)
        self.assertIn("mcp_servers.remote.http_headers.Authorization", result.stderr)
        self.assertNotIn("literal-secret-material", result.stderr)

    def test_drift_reports_difference_without_printing_contents(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "source.toml"
            live = Path(tmp) / "live.toml"
            source.write_text('model = "source-model"\n')
            live.write_text('model = "live-model"\n')

            result = self.run_cli("drift", "--source", str(source), "--live", str(live))

        self.assertEqual(result.returncode, 1)
        self.assertIn("Codex config drift detected", result.stdout)
        self.assertNotIn("source-model", result.stdout + result.stderr)
        self.assertNotIn("live-model", result.stdout + result.stderr)

    def test_release_without_apply_does_not_write(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "config.toml"

            result = self.run_cli(
                "release",
                "--source",
                str(FIXTURES / "valid.toml"),
                "--policy",
                str(POLICY),
                "--target",
                str(target),
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse(target.exists())
            self.assertIn("dry run", result.stdout.lower())

    def test_release_apply_writes_identical_private_file(self) -> None:
        source = FIXTURES / "valid.toml"
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "nested" / "config.toml"

            result = self.run_cli(
                "release",
                "--source",
                str(source),
                "--policy",
                str(POLICY),
                "--target",
                str(target),
                "--apply",
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(target.read_bytes(), source.read_bytes())
            self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)

    def test_release_rejects_invalid_source_before_writing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "config.toml"

            result = self.run_cli(
                "release",
                "--source",
                str(FIXTURES / "plaintext-secret.toml"),
                "--policy",
                str(POLICY),
                "--target",
                str(target),
                "--apply",
            )

            self.assertEqual(result.returncode, 1)
            self.assertFalse(target.exists())

    def test_repository_validation_runs_focused_codex_policy_check(self) -> None:
        result = subprocess.run(
            ["bash", str(ROOT / "tests" / "validate.sh"), "--only", "codex"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Codex MCP config policy", result.stdout)

    def test_dotfiles_codex_check_validates_canonical_config_without_live_file(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "config.toml"
            result = subprocess.run(
                ["bash", str(ROOT / "bin" / "dotfiles"), "codex-check"],
                cwd=ROOT,
                env={**os.environ, "CODEX_CONFIG_TARGET": str(target)},
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Codex MCP policy: PASS", result.stdout)
        self.assertIn("live config not found", result.stdout.lower())

    def test_dotfiles_codex_release_is_dry_run_by_default(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "config.toml"
            result = subprocess.run(
                ["bash", str(ROOT / "bin" / "dotfiles"), "codex-release"],
                cwd=ROOT,
                env={**os.environ, "CODEX_CONFIG_TARGET": str(target)},
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertFalse(target.exists())
            self.assertIn("dry run", result.stdout.lower())

    def test_dotfiles_codex_release_apply_copies_private_config(self) -> None:
        source = ROOT / "codex" / "config.toml"
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "config.toml"
            result = subprocess.run(
                [
                    "bash",
                    str(ROOT / "bin" / "dotfiles"),
                    "codex-release",
                    "--apply",
                ],
                cwd=ROOT,
                env={**os.environ, "CODEX_CONFIG_TARGET": str(target)},
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(target.read_bytes(), source.read_bytes())
            self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)

    def test_dotfiles_propagates_codex_release_failure(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            blocker = Path(tmp) / "not-a-directory"
            blocker.write_text("block")
            target = blocker / "config.toml"
            result = subprocess.run(
                [
                    "bash",
                    str(ROOT / "bin" / "dotfiles"),
                    "codex-release",
                    "--apply",
                ],
                cwd=ROOT,
                env={**os.environ, "CODEX_CONFIG_TARGET": str(target)},
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)


VALUE = "value-that-must-never-be-printed"
DROPPED = ": live only, dropped by release"
ADDED = ": release only, added"

RELEASE_TOML = f"""
[mcp_servers.pal]
command = "pal"
env_vars = ["OPENAI_API_KEY", "GEMINI_API_KEY"]

[mcp_servers.pal.env]
LOG_LEVEL = "INFO"

[mcp_servers.remote]
url = "https://example.invalid/mcp?key={VALUE}"
bearer_token_env_var = "REMOTE_TOKEN"

[mcp_servers.remote.env_http_headers]
X-Api-Key = "REMOTE_API_KEY"
"""


class CodexConfigPreflightTest(unittest.TestCase):
    def preflight(
        self, live: str, release: str = RELEASE_TOML, *accept_drop: str
    ) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as tmp:
            live_path = Path(tmp) / "live.toml"
            release_path = Path(tmp) / "release.toml"
            live_path.write_text(live)
            release_path.write_text(release)
            accept_args = [
                arg for drop in accept_drop for arg in ("--accept-drop", drop)
            ]
            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "preflight",
                    "--live",
                    str(live_path),
                    "--source",
                    str(release_path),
                    *accept_args,
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )
        self.assertNotIn(VALUE, result.stdout + result.stderr)
        return result

    def test_identical_configs_are_clean(self) -> None:
        result = self.preflight(RELEASE_TOML)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout,
            "[pal] both\n[remote] both\nCodex config preflight: clean\n",
        )

    def test_inherited_name_removed_by_release_fails(self) -> None:
        live = RELEASE_TOML.replace(
            '"GEMINI_API_KEY"]', '"GEMINI_API_KEY", "AZURE_OPENAI_API_KEY"]'
        ).replace('LOG_LEVEL = "INFO"', f'LOG_LEVEL = "INFO"\nAZURE_KEY = "{VALUE}"')

        result = self.preflight(live)

        self.assertEqual(result.returncode, 1)
        self.assertIn("[pal] both", result.stdout)
        self.assertIn(f"pal.env_vars.AZURE_OPENAI_API_KEY{DROPPED}\n", result.stdout)
        self.assertIn(f"pal.env.AZURE_KEY{DROPPED}\n", result.stdout)
        self.assertIn("FAIL: unaccepted drops: 2;", result.stderr)

    def test_accepted_drops_pass(self) -> None:
        live = RELEASE_TOML.replace(
            '"GEMINI_API_KEY"]', '"GEMINI_API_KEY", "AZURE_OPENAI_API_KEY"]'
        )

        result = self.preflight(live, RELEASE_TOML, "pal.env_vars.AZURE_OPENAI_API_KEY")
        server_wide = self.preflight(live, RELEASE_TOML, "pal")

        self.assertEqual(server_wide.returncode, 1)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(
            f"pal.env_vars.AZURE_OPENAI_API_KEY{DROPPED} (accepted)", result.stdout
        )
        self.assertIn("Codex config preflight: PASS", result.stdout)

    def test_inherited_name_added_by_release_is_reported(self) -> None:
        live = RELEASE_TOML.replace(', "GEMINI_API_KEY"]', "]")

        result = self.preflight(live)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"pal.env_vars.GEMINI_API_KEY{ADDED}", result.stdout)
        self.assertIn("Codex config preflight: PASS", result.stdout)

    def test_renamed_bearer_and_header_variables_count_as_drops(self) -> None:
        live = RELEASE_TOML.replace('"REMOTE_TOKEN"', '"OLD_REMOTE_TOKEN"').replace(
            '"REMOTE_API_KEY"', '"OLD_REMOTE_API_KEY"'
        )

        result = self.preflight(live)

        self.assertEqual(result.returncode, 1)
        for line in (
            f"remote.bearer_token_env_var.OLD_REMOTE_TOKEN{DROPPED}",
            f"remote.bearer_token_env_var.REMOTE_TOKEN{ADDED}",
            f"remote.env_http_headers.X-Api-Key.OLD_REMOTE_API_KEY{DROPPED}",
            f"remote.env_http_headers.X-Api-Key.REMOTE_API_KEY{ADDED}",
        ):
            self.assertIn(line, result.stdout)

    def test_live_only_server_fails_unless_accepted(self) -> None:
        live = RELEASE_TOML + (
            '\n[mcp_servers.legacy]\ncommand = "legacy"\n'
            'env_vars = [{ name = "LEGACY_TOKEN", source = "remote" }]\n'
            f'[mcp_servers.legacy.env]\nLEGACY_SECRET = "{VALUE}"\n'
        )

        rejected = self.preflight(live)
        accepted = self.preflight(live, RELEASE_TOML, "legacy")

        self.assertEqual(rejected.returncode, 1)
        self.assertIn("[legacy] live only", rejected.stdout)
        self.assertIn(f"legacy.env_vars.LEGACY_TOKEN{DROPPED}", rejected.stdout)
        self.assertIn(f"legacy.env.LEGACY_SECRET{DROPPED}", rejected.stdout)
        self.assertIn("FAIL: unaccepted drops: 4;", rejected.stderr)
        self.assertEqual(accepted.returncode, 0, accepted.stderr)

    def test_value_where_variable_name_belongs_is_suppressed(self) -> None:
        live = RELEASE_TOML.replace('"REMOTE_TOKEN"', f'"{VALUE}"')

        result = self.preflight(live)

        self.assertEqual(result.returncode, 2)
        self.assertIn(
            "mcp_servers.remote.bearer_token_env_var holds something other than a "
            "variable name",
            result.stderr,
        )

    def test_credential_shaped_like_a_variable_name_is_rejected_unprinted(
        self,
    ) -> None:
        # Codex review round 3: a GitHub token satisfies the variable-name regex.
        token = synthetic_token("github")
        live = RELEASE_TOML.replace('"REMOTE_TOKEN"', f'"{token}"')

        result = self.preflight(live)

        self.assertEqual(result.returncode, 2)
        self.assertIn(
            "mcp_servers.remote.bearer_token_env_var holds secret-shaped material",
            result.stderr,
        )
        self.assertNotIn(token, result.stdout + result.stderr)

    def test_dotfiles_codex_preflight_compares_live_target_with_reviewed_config(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "config.toml"
            target.write_bytes((ROOT / "codex" / "config.toml").read_bytes())
            result = subprocess.run(
                ["bash", str(ROOT / "bin" / "dotfiles"), "codex-preflight"],
                cwd=ROOT,
                env={**os.environ, "CODEX_CONFIG_TARGET": str(target)},
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("[pal] both", result.stdout)
        self.assertIn("Codex config preflight: clean", result.stdout)


q = json.dumps  # A JSON string is a valid TOML basic string or quoted key.
URL_LINE = f'url = "https://example.invalid/mcp?key={VALUE}"'

# Where a pasted credential can land, as live configs built from RELEASE_TOML.
# The ones preflight prints as entry ids must be refused with exit 2.
ID_PLACEMENTS: dict[str, Callable[[str], str]] = {
    "server name": lambda t: (
        RELEASE_TOML
        + f'\n[mcp_servers.{q(t)}]\ncommand = "x"\nenv = {{ DEBUG = "1" }}\n'
    ),
    "env key": lambda t: RELEASE_TOML.replace(
        'LOG_LEVEL = "INFO"', f'LOG_LEVEL = "INFO"\n{q(t)} = "1"'
    ),
    "env_vars name": lambda t: RELEASE_TOML.replace(
        '"GEMINI_API_KEY"]', f'"GEMINI_API_KEY", {q(t)}]'
    ),
    "env_vars table name": lambda t: RELEASE_TOML.replace(
        '"GEMINI_API_KEY"]',
        f'"GEMINI_API_KEY", {{ name = {q(t)}, source = "remote" }}]',
    ),
    "bearer_token_env_var": lambda t: RELEASE_TOML.replace('"REMOTE_TOKEN"', q(t)),
    "env_http_headers header": lambda t: RELEASE_TOML.replace(
        'X-Api-Key = "REMOTE_API_KEY"', f'{q(t)} = "REMOTE_API_KEY"'
    ),
    "env_http_headers variable": lambda t: RELEASE_TOML.replace(
        '"REMOTE_API_KEY"', q(t)
    ),
    "http_headers header": lambda t: (
        RELEASE_TOML + f'\n[mcp_servers.remote.http_headers]\n{q(t)} = "codex"\n'
    ),
}
VALUE_PLACEMENTS: dict[str, Callable[[str], str]] = {
    "env value": lambda t: RELEASE_TOML.replace(
        'LOG_LEVEL = "INFO"', f"LOG_LEVEL = {q(t)}"
    ),
    "http_headers value": lambda t: (
        RELEASE_TOML + f"\n[mcp_servers.remote.http_headers]\nUser-Agent = {q(t)}\n"
    ),
    "url": lambda t: RELEASE_TOML.replace(
        URL_LINE, f"url = {q('https://example.invalid/mcp?key=' + t)}"
    ),
    "command": lambda t: RELEASE_TOML.replace('command = "pal"', f"command = {q(t)}"),
    "args": lambda t: RELEASE_TOML.replace(
        'command = "pal"', f'command = "pal"\nargs = ["--api-key", {q(t)}]'
    ),
}

MCP_LIST_ROWS = """\
Name  Command  Args  Env  Cwd  Status  Auth
{token}  pal  --api-key {token}  OPENAI_API_KEY=*****  -  enabled  Unsupported

Name  Url  Bearer Token Env Var  Status  Auth
remote  https://example.invalid/mcp?key={token}  {token}  enabled  Bearer token
"""


class CodexConfigRedactionTest(unittest.TestCase):
    """No SYNTHETIC token, in any field, reaches stdout or stderr."""

    def run_on_configs(self, command: str, config: str) -> tuple[int, str]:
        tomllib.loads(config)
        with tempfile.TemporaryDirectory() as tmp:
            config_path = Path(tmp) / "config.toml"
            reference_path = Path(tmp) / "reference.toml"
            config_path.write_text(config)
            reference_path.write_text(RELEASE_TOML)
            if command == "check":
                argv = ["check", "--config", str(config_path), "--policy", str(POLICY)]
            elif command == "preflight live":
                argv = ["preflight", "--live", str(config_path)]
                argv += ["--source", str(reference_path)]
            else:
                argv = ["preflight", "--live", str(reference_path)]
                argv += ["--source", str(config_path)]
            return run_in_process(*argv)

    def assert_not_leaked(
        self, token: str, output: str, surroundings: str = ""
    ) -> None:
        self.assertEqual(leaked_fragments(token, output, surroundings), set(), output)

    def test_detector_recognizes_every_synthetic_shape(self) -> None:
        for kind in TOKEN_SHAPES:
            token = synthetic_token(kind)
            with self.subTest(kind=kind):
                self.assertTrue(CODEX_CONFIG.is_secret_value(token))
                self.assert_not_leaked(token, CODEX_CONFIG.redact(token))

    def test_detector_leaves_names_and_codex_status_alone(self) -> None:
        for text in (
            "AZURE_OPENAI_API_KEY",
            "NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S",
            "pal.env_vars.AZURE_OPENAI_API_KEY_2026: live only, dropped by release",
            "remote.env_http_headers.X-Api-Key.REMOTE_API_KEY: release only, added",
            "OPENAI_API_KEY=*****",
            "remote  https://example.invalid/mcp  REMOTE_TOKEN  enabled  Bearer token",
            "https://your-resource.openai.azure.com/",
            "a956835d020762cb2b570053af06f643a11c0ecc",
            "ambientSuggestions2Enabled",
            "-----BEGIN PUBLIC KEY-----",
        ):
            with self.subTest(text=text):
                self.assertEqual(CODEX_CONFIG.redact(text), text)

    def test_check_never_prints_a_token_from_any_field(self) -> None:
        for kind in TOKEN_SHAPES:
            token = synthetic_token(kind)
            for field, place in {**ID_PLACEMENTS, **VALUE_PLACEMENTS}.items():
                with self.subTest(kind=kind, field=field):
                    _, output = self.run_on_configs("check", place(token))
                    self.assert_not_leaked(token, output)

    def test_preflight_refuses_a_token_where_an_id_belongs(self) -> None:
        for kind in TOKEN_SHAPES:
            token = synthetic_token(kind)
            for field, place in ID_PLACEMENTS.items():
                for side in ("preflight live", "preflight release"):
                    with self.subTest(kind=kind, field=field, side=side):
                        code, output = self.run_on_configs(side, place(token))
                        self.assertEqual(code, 2, output)
                        self.assertIn("Codex config preflight: ERROR:", output)
                        self.assert_not_leaked(token, output)

    def test_preflight_never_prints_a_token_held_as_a_value(self) -> None:
        for kind in TOKEN_SHAPES:
            token = synthetic_token(kind)
            for field, place in VALUE_PLACEMENTS.items():
                for side in ("preflight live", "preflight release"):
                    with self.subTest(kind=kind, field=field, side=side):
                        code, output = self.run_on_configs(side, place(token))
                        self.assertNotEqual(code, 2, output)
                        self.assert_not_leaked(token, output)

    def test_redact_masks_codex_mcp_list_rows(self) -> None:
        for kind in TOKEN_SHAPES:
            token = synthetic_token(kind)
            with self.subTest(kind=kind):
                code, output = run_in_process(
                    "redact", stdin=MCP_LIST_ROWS.format(token=token)
                )
                self.assertEqual(code, 0)
                self.assert_not_leaked(token, output, MCP_LIST_ROWS.format(token=""))
                self.assertIn("OPENAI_API_KEY=*****", output)
                self.assertTrue(output.endswith("enabled  Bearer token\n"), output)

    def test_dotfiles_codex_redact_filters_stdin(self) -> None:
        token = synthetic_token("github")
        result = subprocess.run(
            ["bash", str(ROOT / "bin" / "dotfiles"), "codex-redact"],
            cwd=ROOT,
            input=f"pal  {token}  Bearer token\n",
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "pal  <redacted>  Bearer token\n")


# Private keys are generated per run into a temporary directory by the tools
# that make real ones, so every key is SYNTHETIC and none is ever committed.
PASSPHRASE = "SYNTHETIC-passphrase"
TRADITIONAL = ("-traditional",)
ENCRYPTED_PKCS8 = ("-aes-256-cbc", "-passout", f"pass:{PASSPHRASE}")
ENCRYPTED_TRADITIONAL = ("-traditional", "-aes256", "-passout", f"pass:{PASSPHRASE}")


def tool(*argv: str, stdin: str | None = None) -> str:
    return subprocess.run(
        argv, input=stdin, text=True, capture_output=True, check=True
    ).stdout


def rsa(bits: int) -> tuple[str, ...]:
    return ("genpkey", "-algorithm", "RSA", "-pkeyopt", f"rsa_keygen_bits:{bits}")


def ec(curve: str) -> tuple[str, ...]:
    return ("genpkey", "-algorithm", "EC", "-pkeyopt", f"ec_paramgen_curve:{curve}")


def dsa(bits: int) -> tuple[str, ...]:
    return ("dsaparam", "-noout", "-genkey", str(bits))


def openssl_key(*generate: str, output: tuple[str, ...] = ()) -> Callable[[Path], str]:
    def key(_: Path) -> str:
        pkcs8 = tool("openssl", *generate)
        return tool("openssl", "pkey", *output, stdin=pkcs8) if output else pkcs8

    return key


def ssh_key(
    kind: str, bits: int | None = None, *, passphrase: str = "", key_format: str = ""
) -> Callable[[Path], str]:
    def key(workdir: Path) -> str:
        path = workdir / "id"
        argv = ["ssh-keygen", "-q", "-t", kind, "-N", passphrase, "-C", "SYNTHETIC"]
        if bits:
            argv += ["-b", str(bits)]
        if key_format:
            argv += ["-m", key_format]
        tool(*argv, "-f", str(path))
        return path.read_text()

    return key


def pgp_key(algorithm: str) -> Callable[[Path], str]:
    def key(home: Path) -> str:
        gpg = ("gpg", "--homedir", str(home), "--batch", "--passphrase", "")
        try:
            tool(*gpg, "--quick-gen-key", "SYNTHETIC", algorithm, "default", "never")
            return tool(*gpg, "--armor", "--export-secret-keys")
        finally:
            tool("gpgconf", "--homedir", str(home), "--kill", "gpg-agent")

    return key


class SshReader:
    def __init__(self, data: bytes) -> None:
        self.data, self.offset = data, 0

    def uint32(self) -> int:
        self.offset += 4
        return int.from_bytes(self.data[self.offset - 4 : self.offset])

    def string(self) -> bytes:
        length = self.uint32()
        self.offset += length
        return self.data[self.offset - length : self.offset]


def ssh_string(data: bytes) -> bytes:
    return len(data).to_bytes(4) + data


def base64_lines(data: bytes) -> list[str]:
    encoded = base64.b64encode(data).decode()
    return [encoded[i : i + 64] for i in range(0, len(encoded), 64)]


def putty_key(openssh: Callable[[Path], str]) -> Callable[[Path], str]:
    """The same key as an unencrypted PuTTY .ppk v3 file. puttygen is not
    installed, so the file is assembled here from the OpenSSH key."""

    def key(workdir: Path) -> str:
        armored = openssh(workdir).strip().splitlines()[1:-1]
        outer = SshReader(base64.b64decode("".join(armored)))
        outer.offset = len(b"openssh-key-v1\0")
        _cipher, _kdf, _kdf_options = outer.string(), outer.string(), outer.string()
        outer.uint32()  # number of keys
        public = outer.string()
        inner = SshReader(outer.string())
        inner.offset += 8  # two check integers
        algorithm = inner.string()
        if algorithm == b"ssh-rsa":
            _n, _e, d, iqmp, p, q = (inner.string() for _ in range(6))
            private_fields = [d, p, q, iqmp]
        elif algorithm == b"ssh-ed25519":
            _public, keypair = inner.string(), inner.string()
            private_fields = [keypair[:32]]
        else:
            _curve, _point, scalar = (inner.string() for _ in range(3))
            private_fields = [scalar]
        private = b"".join(map(ssh_string, private_fields))
        mac_input = (algorithm, b"none", b"SYNTHETIC", public, private)
        mac = hmac.new(b"", b"".join(map(ssh_string, mac_input)), hashlib.sha256)
        public_lines, private_lines = base64_lines(public), base64_lines(private)
        return "\n".join(
            [
                f"PuTTY-User-Key-File-3: {algorithm.decode()}",
                "Encryption: none",
                "Comment: SYNTHETIC",
                f"Public-Lines: {len(public_lines)}",
                *public_lines,
                f"Private-Lines: {len(private_lines)}",
                *private_lines,
                f"Private-MAC: {mac.hexdigest()}",
                "",
            ]
        )

    return key


SYNTHETIC_KEYS: dict[str, Callable[[Path], str]] = {
    **{
        f"openssl-rsa-{bits}-{form}": openssl_key(*rsa(bits), output=output)
        for bits in (1024, 2048, 4096)
        for form, output in (("pkcs8", ()), ("traditional", TRADITIONAL))
    },
    "openssl-rsa-2048-encrypted-pkcs8": openssl_key(*rsa(2048), output=ENCRYPTED_PKCS8),
    "openssl-rsa-2048-encrypted-traditional": openssl_key(
        *rsa(2048), output=ENCRYPTED_TRADITIONAL
    ),
    **{
        f"openssl-ec-{curve}-traditional": openssl_key(*ec(curve), output=TRADITIONAL)
        for curve in ("P-256", "P-384", "P-521")
    },
    "openssl-ec-P-256-pkcs8": openssl_key(*ec("P-256")),
    "openssl-ec-P-384-encrypted-pkcs8": openssl_key(
        *ec("P-384"), output=ENCRYPTED_PKCS8
    ),
    **{
        f"openssl-dsa-{bits}-traditional": openssl_key(*dsa(bits), output=TRADITIONAL)
        for bits in (1024, 2048)
    },
    "openssl-dsa-2048-pkcs8": openssl_key(*dsa(2048)),
    "openssl-ed25519-pkcs8": openssl_key("genpkey", "-algorithm", "ED25519"),
    "openssl-ed448-pkcs8": openssl_key("genpkey", "-algorithm", "ED448"),
    **{
        f"openssh-rsa-{bits}": ssh_key("rsa", bits) for bits in (1024, 2048, 3072, 4096)
    },
    **{f"openssh-ecdsa-{bits}": ssh_key("ecdsa", bits) for bits in (256, 384, 521)},
    "openssh-ed25519": ssh_key("ed25519"),
    "openssh-ed25519-encrypted": ssh_key("ed25519", passphrase=PASSPHRASE),
    "openssh-rsa-3072-encrypted": ssh_key("rsa", 3072, passphrase=PASSPHRASE),
    "ssh-keygen-rsa-2048-pem": ssh_key("rsa", 2048, key_format="PEM"),
    "ssh-keygen-ecdsa-256-pkcs8": ssh_key("ecdsa", 256, key_format="PKCS8"),
    **{
        f"pgp-{algorithm}": pgp_key(algorithm)
        for algorithm in ("rsa2048", "rsa4096", "ed25519")
    },
    "putty-rsa-2048": putty_key(ssh_key("rsa", 2048)),
    "putty-rsa-4096": putty_key(ssh_key("rsa", 4096)),
    "putty-ecdsa-256": putty_key(ssh_key("ecdsa", 256)),
    "putty-ed25519": putty_key(ssh_key("ed25519")),
}

SECRET = "<redacted>"
BEFORE = "text before the key\n"
AFTER = "text after the key\n"


def service_account(private_key: str, indent: int | None) -> str:
    return (
        json.dumps(
            {
                "type": "service_account",
                "project_id": "synthetic-project",
                "private_key_id": "0123456789abcdef0123456789abcdef01234567",
                "private_key": private_key,
                "client_email": "synthetic@synthetic-project.iam.gserviceaccount.com",
            },
            indent=indent,
        )
        + "\n"
    )


def key_cases(key: str) -> dict[str, tuple[str, str]]:
    """Input and exact expected output, per way a key reaches the filter."""
    unterminated = key.rstrip("\n").rpartition("\n")[0] + "\n"
    one_line = service_account(key, None)
    value_start = one_line.index('"private_key": "') + len('"private_key": "')
    return {
        "complete": (BEFORE + key + AFTER, BEFORE + SECRET + "\n" + AFTER),
        "no last line": (BEFORE + unterminated + AFTER, BEFORE + SECRET),
        "json one line": (one_line, service_account(SECRET + "\n", None)),
        "json indented": (
            service_account(key, 2),
            service_account(SECRET + "\n", 2),
        ),
        "json cut off": (
            one_line[: value_start + len(key) // 2],
            one_line[:value_start] + SECRET,
        ),
    }


def leaked_key_lines(key: str, output: str) -> list[int]:
    """Lengths (never contents) of the key's lines that output still holds."""
    return [len(line) for line in key.splitlines() if line and line in output]


class CodexConfigSecretBlockTest(unittest.TestCase):
    """Codex review round 4: a private key is suppressed whole, not per line."""

    keys: dict[str, str]

    @classmethod
    def setUpClass(cls) -> None:
        scratch = Path(
            cls.enterClassContext(tempfile.TemporaryDirectory(prefix="keys-"))
        )
        cls.keys = {}
        for name, generate in SYNTHETIC_KEYS.items():
            workdir = scratch / name
            workdir.mkdir(mode=0o700)
            cls.keys[name] = generate(workdir)

    def test_table_holds_every_private_key_format(self) -> None:
        first_lines = {key.splitlines()[0] for key in self.keys.values()}
        for label in (
            "RSA PRIVATE KEY",
            "EC PRIVATE KEY",
            "DSA PRIVATE KEY",
            "OPENSSH PRIVATE KEY",
            "ENCRYPTED PRIVATE KEY",
            "PRIVATE KEY",
            "PGP PRIVATE KEY BLOCK",
        ):
            self.assertIn(f"-----BEGIN {label}-----", first_lines)
        self.assertIn("PuTTY-User-Key-File-3: ssh-rsa", first_lines)
        self.assertTrue(
            any("Proc-Type: 4,ENCRYPTED" in key for key in self.keys.values())
        )

    def test_redact_suppresses_every_key_whole(self) -> None:
        for name, key in self.keys.items():
            for case, (text, expected) in key_cases(key).items():
                with self.subTest(key=name, case=case):
                    code, output = run_in_process("redact", stdin=text)
                    self.assertEqual(code, 0)
                    self.assertEqual(leaked_key_lines(key, output), [])
                    self.assertEqual(output, expected)

    def test_dotfiles_codex_redact_suppresses_every_key(self) -> None:
        text = "".join(BEFORE + key + AFTER for key in self.keys.values())
        result = subprocess.run(
            ["bash", str(ROOT / "bin" / "dotfiles"), "codex-redact"],
            cwd=ROOT,
            input=text,
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0)
        for name, key in self.keys.items():
            with self.subTest(key=name):
                self.assertEqual(
                    leaked_key_lines(key, result.stdout + result.stderr), []
                )
        self.assertEqual(
            result.stdout, (BEFORE + SECRET + "\n" + AFTER) * len(self.keys)
        )


if __name__ == "__main__":
    unittest.main()
