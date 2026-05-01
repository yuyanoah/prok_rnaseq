#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { PREPARE_GFF    } from './modules/local/prepare_gff'
include { BOWTIE2_BUILD  } from './modules/local/bowtie2_build'
include { BOWTIE2_ALIGN  } from './modules/local/bowtie2_align'
include { SAMTOOLS_SORT  } from './modules/local/samtools_sort'
include { SAMTOOLS_INDEX } from './modules/local/samtools_index'
include { FEATURECOUNTS  } from './modules/local/featurecounts'
include { CALC_TPM       } from './modules/local/calc_tpm'

workflow {

    // ── inputs ──────────────────────────────────────────────────────────────
    ch_reads = Channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            def meta  = [id: row.sample, strandedness: row.strandedness ?: 'unstranded',
                         single_end: !row.fastq_2]
            def reads = row.fastq_2
                ? [ file(row.fastq_1, checkIfExists: true),
                    file(row.fastq_2, checkIfExists: true) ]
                : [ file(row.fastq_1, checkIfExists: true) ]
            [ meta, reads ]
        }

    ch_fasta = Channel.fromPath(params.fasta, checkIfExists: true)
    ch_gff   = Channel.fromPath(params.gff,   checkIfExists: true)

    // ── workflow ─────────────────────────────────────────────────────────────
    PREPARE_GFF(ch_gff.first())

    BOWTIE2_BUILD(ch_fasta)

    BOWTIE2_ALIGN(
        ch_reads,
        BOWTIE2_BUILD.out.index.first()
    )

    SAMTOOLS_SORT(BOWTIE2_ALIGN.out.bam)
    SAMTOOLS_INDEX(SAMTOOLS_SORT.out.bam)

    // Collect all BAMs for a single featureCounts run (multi-sample columns)
    ch_bams = SAMTOOLS_SORT.out.bam
        .map { meta, bam -> bam }
        .collect()

    // single_end: true if fastq_2 absent (consistent across all samples assumed)
    ch_single_end = ch_reads.map { meta, reads -> meta.single_end }.first()

    FEATURECOUNTS(ch_bams, PREPARE_GFF.out.gff3, ch_single_end)

    CALC_TPM(FEATURECOUNTS.out.counts)
}
