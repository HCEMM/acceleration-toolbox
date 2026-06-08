#!/bin/bash
set -euo pipefail

WORKING_DIR=01_GitHub
OUTPUT_DIR=pipeline_results
THREADS=8

bash 01_GitHub/scripts/01-qc.sh "$WORKING_DIR" "$OUTPUT_DIR" "$THREADS"

bash 01_GitHub/scripts/02-count-seqs.sh "$OUTPUT_DIR"

bash 01_GitHub/scripts/03-annotation.sh "$OUTPUT_DIR" "$WORKING_DIR/data/db_trimmed.dmnd" "$THREADS"

bash 01_GitHub/scripts/04-build-matrix.sh "$OUTPUT_DIR"

bash 01_GitHub/scripts/05-build-report.sh "$OUTPUT_DIR" "$WORKING_DIR/data/multiqc_config.yaml"
