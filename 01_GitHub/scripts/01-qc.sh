#!/bin/bash
set -euo pipefail

# Activate conda environment
source $(conda info --base)/etc/profile.d/conda.sh
conda activate workshop


READS_DIR=$1
RESULTS_DIR=$2/qc
THREADS=$3
N_FILES=12

mkdir -p "$RESULTS_DIR"

echo "Running FastQC on raw reads"

# GROUP 1 - WRITE HERE THE COMMAND TO RUN FASTQC
# READS ARE GZIPPED AT $READS_DIR
# OUTPUT SHOULD GO TO $RESULTS_DIR
# USE $THREADS
fastqc "$READS_DIR"/*.gz --outdir "$RESULTS_DIR" --threads "$THREADS"

# Check if 12 FastQC reports were generated, and exit code 1 if not
if [ $(ls "$RESULTS_DIR"/*_fastqc.zip | wc -l) -ne $N_FILES ]; then
    echo "Error: Not all FastQC reports were generated. Expected $N_FILES, but found $(ls "$RESULTS_DIR"/*_fastqc.zip | wc -l)."
    exit 1
fi

echo "FastQC complete!"
