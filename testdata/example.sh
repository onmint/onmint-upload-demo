#!/bin/bash
# Script to process user records from a CSV file
# Author: test-user
# Last updated: 2026-01-15

DB_HOST="localhost"
DB_PORT=5432
DB_NAME="sample_db"
MAX_RETRIES=3

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --input) INPUT_FILE="$2"; shift 2 ;;
            --output) OUTPUT_DIR="$2"; shift 2 ;;
            --verbose) VERBOSE=true; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done
}

# Validate that the input file exists and is readable
validate_input() {
    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "Error: Input file '$INPUT_FILE' not found"
        exit 1
    fi
    echo "Processing $(wc -l < "$INPUT_FILE") records..."
}

# Transform and load records
process_records() {
    local count=0
    while IFS=',' read -r id name email status; do
        if [[ "$status" == "active" ]]; then
            echo "$id|$name|$email" >> "$OUTPUT_DIR/active_users.txt"
            ((count++))
        fi
    done < "$INPUT_FILE"
    echo "Processed $count active records"
}

parse_args "$@"
validate_input
process_records
