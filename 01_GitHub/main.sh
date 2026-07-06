#!/bin/bash
set -euo pipefail

# Run this script from the root of the repository
WORKING_DIR=01_GitHub
OUTPUT_DIR=01_GitHub/results
THREADS=8

bash 01_GitHub/scripts/.sh "$WORKING_DIR"/data "$OUTPUT_DIR" "$THREADS"

bash 01_GitHub/scripts/02-summarize-seqs.sh "$WORKING_DIR"/data "$OUTPUT_DIR"/seq_counts.tsv "$THREADS"

bash 01_GitHub/scripts/.sh "$WORKING_DIR"/data "$OUTPUT_DIR" "$WORKING_DIR/data/db_trimmed.dmnd" "$THREADS"

bash 01_GitHub/scripts/.sh "$OUTPUT_DIR" "$OUTPUT_DIR"

bash 01_GitHub/scripts/.sh "$OUTPUT_DIR" "$OUTPUT_DIR" "$WORKING_DIR/data/multiqc_config.yaml"
