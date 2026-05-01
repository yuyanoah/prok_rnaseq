process SAMTOOLS_INDEX {
    tag "$meta.id"
    publishDir "${params.outdir}/bam", mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path(bam), path("${bam}.bai"), emit: bam
    path 'versions.yml',                            emit: versions

    script:
    """
    samtools index -@ ${task.cpus} ${bam}

    cat <<-EOF > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -1 | sed 's/samtools //')
    EOF
    """
}
