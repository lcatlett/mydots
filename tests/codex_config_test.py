import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "bin" / "codex-config"
FIXTURES = ROOT / "tests" / "fixtures" / "codex-config"
POLICY = FIXTURES / "policy.toml"


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


if __name__ == "__main__":
    unittest.main()
