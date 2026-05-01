process SAMTOOLS_SORT {
    tag "$meta.id"
    publishDir "${params.outdir}/bam", mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"), emit: bam
    path 'versions.yml',                            emit: versions

    script:
    """
    samtools sort -@ ${task.cpus} -o ${meta.id}.sorted.bam ${bam}

    cat <<-EOF > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -1 | sed 's/samtools //')
    EOF
    """
}
