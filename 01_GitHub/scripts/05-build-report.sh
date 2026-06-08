#!/bin/bash
set -euo pipefail

RESULTS_DIR=$1
MULTIQC_CONFIG=$2

echo "Generating MultiQC report"

multiqc $RESULTS_DIR -c $MULTIQC_CONFIG -o $RESULTS_DIR/multiqc_report

echo "Report assets copied"