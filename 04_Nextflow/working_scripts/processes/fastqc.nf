process FASTQC {
    tag "FastQC on $sample_id"
    publishDir "${params.outdir}/qc", mode: 'copy'

    container "hcemm/bioinfo-workshop:fastqc"

    input:
    tuple val(sample_id), path(reads)

    output:
    path "*_fastqc.{zip,html}", emit: qc_results

    script:
    """
    fastqc -t ${task.cpus} ${reads[0]} ${reads[1]}
    """
}
