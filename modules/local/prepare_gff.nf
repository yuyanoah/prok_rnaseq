process PREPARE_GFF {
    tag "$gff.baseName"
    publishDir "${params.outdir}/gff", mode: 'copy'

    input:
    path gff

    output:
    path "${gff.baseName}.fixed.gff3", emit: gff3
    path 'versions.yml',               emit: versions

    script:
    """
    # Detect format: Bakta has locus_tag=, Prodigal has only ID=
    if grep -v '^#' ${gff} | grep -q 'locus_tag='; then
        # Already has locus_tag: use as-is
        cp ${gff} ${gff.baseName}.fixed.gff3
    else
        # Prodigal GFF: add gene/CDS hierarchy with locus_tag
        prodigal_gff2gff3.py ${gff} > ${gff.baseName}.fixed.gff3
    fi

    cat <<-EOF > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
    EOF
    """
}
