#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { PREPARE_GFF    } from './modules/local/prepare_gff'
include { BOWTIE2_BUILD  } from './modules/local/bowtie2_build'
include { BOWTIE2_ALIGN  } from './modules/local/bowtie2_align'
include { SAMTOOLS_SORT  } from './modules/local/samtools_sort'
include { SAMTOOLS_INDEX } from './modules/local/samtools_index'
include { FEATURECOUNTS  } from './modules/local/featurecounts'
include { CALC_TPM       } from './modules/local/calc_tpm'
include { MAKE_SUMMARY   } from './modules/local/make_summary'

workflow {

    // ── inputs ──────────────────────────────────────────────────────────────
    def r1_file    = file(params.r1, checkIfExists: true)
    def r2_file    = params.r2 ? file(params.r2, checkIfExists: true) : null
    def single_end = (params.r2 == null)
    def sample_id  = params.sample
        ?: r1_file.name
            .replaceFirst(/(?i)[_\.]R?1[_.].*/,  '')
            .replaceFirst(/(?i)\.(fastq|fq)(\.gz)?$/, '')
        ?: 'sample'
    def meta  = [id: sample_id, strandedness: params.strandedness ?: 'unstranded',
                 single_end: single_end]
    def reads = r2_file ? [r1_file, r2_file] : [r1_file]

    ch_reads = Channel.of([meta, reads])

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
        .map { m, bam -> bam }
        .collect()

    // single_end: true if fastq_2 absent (consistent across all samples assumed)
    ch_single_end = ch_reads.map { m, r -> m.single_end }.first()

    FEATURECOUNTS(ch_bams, PREPARE_GFF.out.gff3, ch_single_end)

    CALC_TPM(FEATURECOUNTS.out.counts)

    ch_summary = Channel.of(sample_id)
        .combine(BOWTIE2_ALIGN.out.log)
        .combine(FEATURECOUNTS.out.summary)
        .combine(CALC_TPM.out.tpm)

    MAKE_SUMMARY(ch_summary)
}
