process CALC_TPM {
    publishDir "${params.outdir}/tpm", mode: 'copy'

    input:
    path counts

    output:
    path 'tpm.tsv',      emit: tpm
    path 'versions.yml', emit: versions

    script:
    """
    calc_tpm.py ${counts} tpm.tsv

    cat <<-EOF > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
        pandas: \$(python3 -c 'import pandas; print(pandas.__version__)')
    EOF
    """
}
