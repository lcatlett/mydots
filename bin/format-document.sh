#!/bin/bash

# Professional Document Formatter (doc-polish) - Fast Bash Version
# Uses pure bash/sed/awk for instant formatting without API calls
# Based on PROFESSIONAL_FORMATTING_PROMPT.md

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage function
usage() {
    cat << EOF
Professional Document Formatter (Fast Mode)

USAGE:
    $0 [OPTIONS] <input_file> [output_file]

DESCRIPTION:
    Applies professional formatting standards to documents using bash text processing.
    Transforms informal, technical, or inflammatory language into executive-ready content.
    Fast mode - no API calls, instant results.

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -p, --preview       Preview changes without saving (output to stdout)
    -b, --backup        Create backup of original file
    -f, --force         Overwrite output file if it exists

ARGUMENTS:
    input_file          Path to the document to format
    output_file         Path for the formatted output (optional, defaults to input_file.formatted)

EXAMPLES:
    # Format a document and save to new file
    $0 report.md report_professional.md

    # Preview formatting changes
    $0 --preview technical_doc.md

    # Format with backup of original
    $0 --backup --force analysis.md

EOF
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Apply professional formatting transformations
format_document() {
    local content="$1"
    
    # Step 1: Remove emojis and symbols
    content=$(echo "$content" | sed -E '
        s/🚨//g
        s/⚠️//g
        s/❌//g
        s/✅//g
        s/☑️//g
        s/🔍//g
        s/📊//g
        s/💰//g
        s/🔥//g
        s/⚡//g
        s/💡//g
        s/🎯//g
        s/📈//g
        s/📉//g
        s/⭐//g
        s/🚀//g
    ')
    
    # Step 2: Replace inflammatory language (case-insensitive, word boundaries)
    content=$(echo "$content" | sed -E '
        s/\bCATASTROPHIC FAILURE\b/significant performance issue/gi
        s/\bCATASTROPHIC\b/significant/gi
        s/\bCATASTROPHE\b/significant issue/gi
        s/\bCOMPLETE DISASTER\b/significant issue/gi
        s/\bDISASTER\b/issue/gi
        s/\bDISASTROUS\b/problematic/gi
        s/\bCRITICAL FAILURE\b/critical issue/gi
        s/\bBROKEN ARCHITECTURE\b/architecture requiring optimization/gi
        s/\bBROKEN\b/requiring optimization/gi
        s/\bFAILURE\b/suboptimal performance/gi
        s/\bFAILED\b/did not complete/gi
        s/\bWRONG\b/alternative approach/gi
        s/\bSTUCK WORKERS\b/long-running processes/gi
        s/\bCOMPLETELY STUCK\b/experiencing extended processing times/gi
        s/\bSTUCK\b/long-running/gi
        s/\bDEAD PROCESSES\b/inactive processes/gi
        s/\bDEAD\b/inactive/gi
        s/\bKILLED\b/terminated/gi
        s/\bKILLING PERFORMANCE\b/degrading performance/gi
        s/\bKILLING\b/terminating/gi
        s/\bWASTED RESOURCES\b/suboptimal resource allocation/gi
        s/\bWASTED\b/suboptimally allocated/gi
        s/\bWASTING\b/inefficiently allocating/gi
        s/\bWASTE\b/inefficient allocation/gi
        s/\bBLOAT\b/increased utilization/gi
        s/\bBLEEDING MONEY\b/increased operational costs/gi
        s/\bMONEY BLEEDING\b/operational cost increases/gi
        s/\bBLEEDING\b/experiencing/gi
        s/\bCRASHED\b/stopped unexpectedly/gi
        s/\bCRASHING\b/stopping unexpectedly/gi
        s/\bSTUPID\b/suboptimal/gi
        s/\bIDIOTIC\b/inefficient/gi
        s/\bTERRIBLE\b/suboptimal/gi
        s/\bHORRIBLE\b/problematic/gi
        s/\bAWFUL\b/concerning/gi
    ')
    
    # Step 3: Replace business/technical terms (already handled in step 2)
    content=$(echo "$content" | sed -E '
        s/\bREVENUE AT RISK\b/revenue exposure/gi
        s/\bCUSTOMER CHURN\b/customer retention risk/gi
        s/\bARCHITECTURAL DISASTER\b/architectural optimization opportunity/gi
    ')
    
    # Step 4: Convert common questions to statements
    content=$(echo "$content" | sed -E '
        s/WHY IS THIS HAPPENING\?/Root cause analysis:/gi
        s/WHAT SHOULD WE DO\?/Recommended actions:/gi
        s/HOW DO WE FIX THIS\?/Resolution approach:/gi
        s/WHAT WENT WRONG\?/Issue analysis:/gi
    ')
    
    # Step 5: Replace URGENT/CRITICAL with professional terms
    content=$(echo "$content" | sed -E '
        s/\bURGENT ACTION REQUIRED\b/high-priority action required/gi
        s/\bURGENT\b/high-priority/gi
        s/\bCRITICAL\b/significant/gi
        s/\bIMMEDIATE ACTION\b/prompt action/gi
        s/\bIMMEDIATELY\b/promptly/gi
    ')
    
    # Step 6: Clean up excessive punctuation
    content=$(echo "$content" | sed -E '
        s/!!!+/./g
        s/\?\?\?+/?/g
        s/\.\.\.+/.../g
    ')
    
    # Step 7: Convert ALL CAPS headers to Title Case using Python
    content=$(echo "$content" | python3 -c '
import sys
import re

for line in sys.stdin:
    # Check if line is a markdown header
    if re.match(r"^#{1,6}\s", line):
        # Convert header to title case
        # First lowercase everything after the #
        parts = line.split(None, 1)
        if len(parts) > 1:
            header_marks = parts[0]
            header_text = parts[1]
            # Title case the text
            header_text = header_text.title()
            line = header_marks + " " + header_text
    print(line, end="")
')
    
    # Step 8: Clean up multiple spaces
    content=$(echo "$content" | sed -E 's/  +/ /g')
    
    # Step 9: Remove trailing whitespace
    content=$(echo "$content" | sed -E 's/[[:space:]]+$//')
    
    echo "$content"
}

# Main function
main() {
    local input_file=""
    local output_file=""
    local verbose=false
    local preview=false
    local backup=false
    local force=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -p|--preview)
                preview=true
                shift
                ;;
            -b|--backup)
                backup=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$input_file" ]]; then
                    input_file="$1"
                elif [[ -z "$output_file" ]]; then
                    output_file="$1"
                else
                    log_error "Too many arguments"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$input_file" ]]; then
        log_error "Input file is required"
        usage
        exit 1
    fi
    
    # Check if input file exists
    if [[ ! -f "$input_file" ]]; then
        log_error "Input file not found: $input_file"
        exit 1
    fi
    
    if [[ ! -r "$input_file" ]]; then
        log_error "Cannot read input file: $input_file"
        exit 1
    fi
    
    # Set default output file
    if [[ -z "$output_file" ]]; then
        if [[ "$preview" == true ]]; then
            output_file="/dev/stdout"
        else
            output_file="${input_file}.formatted"
        fi
    fi
    
    # Check if output file exists
    if [[ "$output_file" != "/dev/stdout" && -f "$output_file" && "$force" != true ]]; then
        log_error "Output file already exists: $output_file"
        log_error "Use --force to overwrite or choose a different output file"
        exit 1
    fi
    
    # Create backup if requested
    if [[ "$backup" == true && "$output_file" != "/dev/stdout" ]]; then
        local backup_file="${input_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$input_file" "$backup_file"
        log_info "Created backup: $backup_file"
    fi
    
    # Read input file
    local input_content
    input_content=$(cat "$input_file")
    
    # Apply formatting
    if [[ "$verbose" == true ]]; then
        log_info "Applying professional formatting transformations..."
    fi
    
    local formatted_content
    formatted_content=$(format_document "$input_content")
    
    # Save formatted content
    echo "$formatted_content" > "$output_file"
    
    if [[ "$output_file" != "/dev/stdout" ]]; then
        log_success "Document formatted successfully: $output_file"
        
        if [[ "$verbose" == true ]]; then
            local input_lines output_lines
            input_lines=$(echo "$input_content" | wc -l | tr -d ' ')
            output_lines=$(echo "$formatted_content" | wc -l | tr -d ' ')
            log_info "Input: $input_lines lines, Output: $output_lines lines"
        fi
    fi
}

# Run main function
main "$@"

