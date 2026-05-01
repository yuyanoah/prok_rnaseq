process BOWTIE2_BUILD {
    tag "$fasta.baseName"
    publishDir "${params.outdir}/bowtie2_index", mode: 'copy', enabled: false

    input:
    path fasta

    output:
    path 'bowtie2_index', emit: index
    path 'versions.yml',  emit: versions

    script:
    """
    mkdir bowtie2_index
    bowtie2-build --threads ${task.cpus} ${fasta} bowtie2_index/genome

    cat <<-EOF > versions.yml
    "${task.process}":
        bowtie2: \$(bowtie2 --version | head -1 | sed 's/.*version //')
    EOF
    """
}
