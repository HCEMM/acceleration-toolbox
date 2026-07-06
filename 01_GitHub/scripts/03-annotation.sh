#!/bin/bash
set -euo pipefail

READS_DIR=$1
RESULTS_DIR=$2
DB=$3
THREADS=$4
MAX_TARGET_SEQS=1
N_FILES=12

mkdir -p "$RESULTS_DIR"

echo "Running annotation against database of glucocorticoid-responsive genes"

for FILE in "$READS_DIR"/*.fastq.gz; 
do 
    echo "Annotating file: $FILE"

    # GROUP 3 - WRITE HERE THE COMMAND TO RUN DIAMOND BLASTX
    # Explicitly declare and assign the variable safely
    SAMPLE_NAME=$(basename "$FILE" .fastq.gz)
    
    # Run DIAMOND blastx using the verified variable
    diamond blastx \
        --query "$FILE" \
        --db "$DB" \
        --out "$RESULTS_DIR/${SAMPLE_NAME}_matches.tab" \
        --threads "$THREADS" \
        --max-target-seqs "$MAX_TARGET_SEQS" \
        --outfmt 6

done

# check if 12 annotation results were generated, and exit code 1 if not
if [ $(ls "$RESULTS_DIR"/*_matches.tab | wc -l) -ne $N_FILES ]; then
    echo "Error: Not all annotation results were generated. Expected $N_FILES, but found $(ls "$RESULTS_DIR"/*_matches.tab | wc -l)."
    exit 1
fi

# tip: $(basename "$FILE" .fastq.gz) extracts the sample name from the filename by removing the directory path and the .fastq.gz extension

echo "Annotation complete"