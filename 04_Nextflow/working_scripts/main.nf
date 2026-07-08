#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// --- PARAMETERS ---
params.reads         = "/common/2nd_workshop/*_workshop_{1,2}.fastq.gz"
params.transcriptome = "$projectDir/data/Homo_sapiens.GRCh38.cdna.all.fa"
params.metadata      = "$projectDir/data/samples.csv"       // Added: Required for R (limma)
params.tx2gene       = "$projectDir/data/tx2gene/tx2gene.csv"       // Added: Required for R (tximport)
params.outdir        = "$projectDir/results"

// --- MODULE IMPORTS ---
include { FASTQC }       from './processes/fastqc.nf'
include { TRIMMOMATIC }  from './processes/trimming.nf'
include { SALMON_INDEX } from './processes/salmon.nf'       // Added: Salmon Indexing step
include { SALMON_QUANT } from './processes/salmon.nf'
include { MULTIQC }      from './processes/multiqc.nf'      // Added: MultiQC!
include { R_ANALYSIS }   from './processes/r_analysis.nf'

//ml apptainer!

// --- WORKFLOW ---
workflow {
    // 1. Create channels from input data
    read_pairs_ch    = Channel.fromFilePairs(params.reads, checkIfExists: true).view { "Found sample: ${it[0]}" }
    transcriptome_ch = file(params.transcriptome, checkIfExists: true)
    tx2gene_ch       = file(params.tx2gene, checkIfExists: true)
    metadata_ch      = file(params.metadata, checkIfExists: true)

    // 2. Quality Control & Trimming
    FASTQC(read_pairs_ch)
    TRIMMOMATIC(read_pairs_ch)

    // 3. Transcriptome Indexing & Quantification
    SALMON_INDEX(transcriptome_ch)

    // Pass the trimmed reads and the generated index into Salmon Quant
    SALMON_QUANT(TRIMMOMATIC.out.trimmed_reads, SALMON_INDEX.out.index)


    // 4. Summarize all Quality Control logs
    // We mix the outputs from FastQC, Trimmomatic, and Salmon into one channel for MultiQC
    MULTIQC(
        FASTQC.out.qc_results.mix(
            TRIMMOMATIC.out.log,
            SALMON_QUANT.out.quant_dirs
        ).collect())

    // 5. Differential Expression in R
    // Pass the quantified directories, plus the necessary biological metadata
    R_ANALYSIS(
        SALMON_QUANT.out.quant_dirs.collect(),
        tx2gene_ch,
        metadata_ch
    )
}
