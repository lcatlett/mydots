# Professional Document Formatter (doc-polish)

A custom command-line tool that uses AI to transform any document into professional, executive-ready content by applying standardized formatting and language guidelines.

## Overview

This tool applies the professional formatting standards defined in `PROFESSIONAL_FORMATTING_PROMPT.md` to automatically:

- Remove inflammatory and emotional language
- Convert ALL CAPS to professional case
- Remove emojis and excessive symbols
- Transform questions into analytical statements
- Apply consistent formatting standards
- Ensure executive-appropriate tone

## Installation & Setup

### Prerequisites

1. **AI API Key**: You need a valid Anthropic Claude API key
2. **Dependencies**: `curl` and `jq` must be installed

```bash
# Install jq if not already installed
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

### Setup API Key

Set your AI API key as an environment variable:

```bash
# Add to your ~/.bashrc, ~/.zshrc, or ~/.profile
export CLAUDE_API_KEY="your-api-key-here"

# Or set for current session
export CLAUDE_API_KEY="your-api-key-here"
```

### Make Scripts Accessible

Add the scripts directory to your PATH for global access:

```bash
# Add to your ~/.bashrc, ~/.zshrc, or ~/.profile
export PATH="$PATH:/Users/lindseycatlett/notes/platform/jeli-123/remote-exec-tool/scripts"

# Or create symlinks to a directory already in PATH
ln -s /Users/lindseycatlett/notes/platform/jeli-123/remote-exec-tool/scripts/doc-polish /usr/local/bin/
ln -s /Users/lindseycatlett/notes/platform/jeli-123/remote-exec-tool/scripts/format-document.sh /usr/local/bin/
```

## Usage

### Basic Usage

```bash
# Format a document (creates input_file.formatted)
./scripts/doc-polish document.md

# Format with specific output file
./scripts/doc-polish document.md professional_document.md

# Preview changes without saving
./scripts/doc-polish --preview document.md
```

### Advanced Usage

```bash
# Create backup of original file
./scripts/format-document.sh --backup --force report.md

# Verbose output with statistics
./scripts/format-document.sh --verbose analysis.md

# Specify API key directly
./scripts/format-document.sh --api-key "your-key" document.md

# Format multiple files
for file in *.md; do
    ./scripts/doc-polish "$file" "formatted_$file"
done
```

### Command Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --verbose` | Enable verbose output with statistics |
| `-p, --preview` | Preview changes without saving (output to stdout) |
| `-b, --backup` | Create backup of original file |
| `-f, --force` | Overwrite output file if it exists |
| `--api-key KEY` | Specify AI API key directly |

## Examples

### Example 1: Basic Document Formatting

**Input (technical_report.md):**
```markdown
🚨 CRITICAL SYSTEM FAILURE! 🚨

The PHP workers are COMPLETELY STUCK serving massive files! This is CATASTROPHIC and we're BLEEDING MONEY!

WHY IS THIS HAPPENING?
- BROKEN configuration
- NO timeout protection
- WASTED resources
```

**Command:**
```bash
./scripts/doc-polish technical_report.md
```

**Output (technical_report.md.formatted):**
```markdown
System Performance Issue Analysis

PHP worker processes are experiencing extended processing times while serving large files. This represents a significant operational concern requiring immediate attention and resource optimization.

Root Cause Analysis:
- Configuration requires optimization
- Timeout protection needs implementation  
- Resource allocation requires efficiency improvements
```

### Example 2: Preview Mode

```bash
# Preview changes before committing
./scripts/doc-polish --preview urgent_memo.md

# Pipe to less for easier reading
./scripts/doc-polish --preview long_document.md | less
```

### Example 3: Batch Processing

```bash
# Format all markdown files in current directory
for file in *.md; do
    echo "Formatting $file..."
    ./scripts/doc-polish --backup "$file" "professional_$file"
done
```

### Example 4: Integration with Git Workflow

```bash
# Format before committing
./scripts/doc-polish --backup README.md
git add README.md.formatted
git commit -m "Add professionally formatted README"

# Format all documentation
find docs/ -name "*.md" -exec ./scripts/doc-polish --backup {} \;
```

## Transformation Examples

### Language Transformations

| Before | After |
|--------|-------|
| 🚨 CRITICAL FAILURE | Critical Issue Identified |
| BROKEN ARCHITECTURE | Architecture Requiring Optimization |
| WASTED RESOURCES | Suboptimal Resource Allocation |
| WHY IS THIS HAPPENING? | Root Cause Analysis Indicates |
| STUCK workers | Long-running Processes |
| BLEEDING money | Increased Operational Costs |

### Formatting Transformations

| Before | After |
|--------|-------|
| `ALL CAPS HEADERS` | `Title Case Headers` |
| `🔍 Analysis shows` | `Analysis Indicates` |
| `❌ WRONG approach` | `Alternative Approach Required` |
| `✅ CORRECT solution` | `Recommended Solution` |

## Troubleshooting

### Common Issues

1. **API Key Not Found**
   ```bash
   [ERROR] AI API key is required
   ```
   **Solution**: Set the `CLAUDE_API_KEY` environment variable

2. **Permission Denied**
   ```bash
   [ERROR] Cannot read input file
   ```
   **Solution**: Check file permissions with `ls -la filename`

3. **Missing Dependencies**
   ```bash
   [ERROR] Missing required dependencies: jq
   ```
   **Solution**: Install missing dependencies using your package manager

4. **API Rate Limits**
   ```bash
   [ERROR] AI API error: Rate limit exceeded
   ```
   **Solution**: Wait a moment and retry, or check your API usage

### Debug Mode

For troubleshooting, you can examine the API request/response:

```bash
# Enable verbose mode for more details
doc-polish --verbose document.md

# Check the temp directory for debugging (before cleanup)
# Modify the script to add: echo "Temp dir: $TEMP_DIR" && sleep 10
```

## File Structure

```
scripts/
├── format-document.sh          # Main formatting script
├── doc-polish                 # Simple wrapper command
└── README_DOC_POLISH.md       # This documentation

data-analysis/
└── PROFESSIONAL_FORMATTING_PROMPT.md  # Formatting guidelines
```

## Integration Ideas

### 1. Git Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
for file in $(git diff --cached --name-only --diff-filter=ACM | grep '\.md$'); do
    ./scripts/doc-polish --backup "$file"
    git add "$file.formatted"
done
```

### 2. CI/CD Pipeline

```yaml
# .github/workflows/format-docs.yml
name: Format Documentation
on: [push]
jobs:
  format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Format documents
        env:
          CLAUDE_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
        run: |
          for file in docs/*.md; do
            ./scripts/doc-polish "$file"
          done
```

### 3. VS Code Integration

Create a VS Code task in `.vscode/tasks.json`:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Format with doc-polish",
            "type": "shell",
            "command": "./scripts/doc-polish",
            "args": ["${file}"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always"
            }
        }
    ]
}
```

## Best Practices

1. **Always backup important documents** using the `--backup` flag
2. **Preview changes first** using `--preview` for critical documents
3. **Set API key as environment variable** rather than passing it as argument
4. **Use version control** to track formatting changes
5. **Test on sample documents** before batch processing
6. **Monitor API usage** to avoid rate limits

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Verify your AI API key and permissions
3. Ensure all dependencies are installed
4. Review the professional formatting prompt for expected transformations

The tool is designed to maintain technical accuracy while transforming language and formatting to professional standards suitable for executive presentation.
