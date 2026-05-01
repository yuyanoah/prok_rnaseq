process BOWTIE2_ALIGN {
    tag "$meta.id"

    input:
    tuple val(meta), path(reads)
    path  index

    output:
    tuple val(meta), path("${meta.id}.sam"), emit: bam
    path "${meta.id}.bowtie2.log",           emit: log
    path 'versions.yml',                     emit: versions

    script:
    def reads_arg = reads.size() == 2 ? "-1 ${reads[0]} -2 ${reads[1]}" : "-U ${reads[0]}"
    """
    bowtie2 \\
        -x ${index}/genome \\
        ${reads_arg} \\
        --threads ${task.cpus} \\
        ${params.bt2_extra_args} \\
        -S ${meta.id}.sam \\
        2> ${meta.id}.bowtie2.log

    cat <<-EOF > versions.yml
    "${task.process}":
        bowtie2: \$(bowtie2 --version | head -1 | sed 's/.*version //')
    EOF
    """
}
