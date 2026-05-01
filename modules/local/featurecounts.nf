process FEATURECOUNTS {
    publishDir "${params.outdir}/featurecounts", mode: 'copy'

    input:
    path bams
    path gff
    val  single_end

    output:
    path 'featureCounts.txt',         emit: counts
    path 'featureCounts.txt.summary', emit: summary
    path 'versions.yml',              emit: versions

    script:
    def strand = params.strandedness == 'forward'  ? 1 :
                 params.strandedness == 'reverse'  ? 2 : 0
    def paired = single_end ? '' : '-p --countReadPairs'
    """
    featureCounts \\
        -a ${gff} \\
        -o featureCounts.txt \\
        -t ${params.fc_feature_type} \\
        -g ${params.fc_group_by} \\
        -s ${strand} \\
        -T ${task.cpus} \\
        ${paired} \\
        ${params.fc_extra_args} \\
        ${bams.join(' ')}

    cat <<-EOF > versions.yml
    "${task.process}":
        subread: \$(featureCounts -v 2>&1 | grep -oP 'v[0-9.]+')
    EOF
    """
}
