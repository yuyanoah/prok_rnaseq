process MAKE_SUMMARY {
    publishDir "${params.outdir}/summary", mode: 'copy'

    input:
    tuple val(sample), path(bt2_log), path(fc_summary), path(tpm)

    output:
    path 'summary.tsv', emit: summary

    script:
    """
    make_summary.py ${sample} ${bt2_log} ${fc_summary} ${tpm} > summary.tsv
    """
}
