# prok_rnaseq

Nextflow pipeline for prokaryotic RNA-seq: bowtie2 genome mapping → featureCounts → TPM.

## Overview

| Step | Tool | Description |
|------|------|-------------|
| GFF preparation | Python | Auto-detect Prodigal/Bakta format; add `locus_tag` if missing |
| Genome index | bowtie2 | Build index from reference FASTA |
| Alignment | bowtie2 | End-to-end genome mapping |
| Sort/index | samtools | Sort and index BAM files |
| Quantification | featureCounts | Count reads overlapping CDS features |
| TPM | Python | Calculate TPM from counts |

## Usage

```bash
nextflow run yuyanoah/prok_rnaseq \
    -profile slurm,singularity \
    --input  samplesheet.csv \
    --fasta  genome.fasta \
    --gff    genome.gff \
    --outdir results
```

## Input

**Samplesheet** (`samplesheet.csv`):
```
sample,fastq_1,fastq_2,strandedness
sample1,/path/r1.fq.gz,/path/r2.fq.gz,unstranded
```

**GFF format** — both Prodigal and Bakta are accepted; format is auto-detected.

## Output

| Path | Description |
|------|-------------|
| `bam/` | Sorted BAM files |
| `featurecounts/` | featureCounts output |
| `tpm/tpm.tsv` | TPM table (genes × samples) |
| `gff/` | Prepared GFF3 |

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--strandedness` | `unstranded` | `unstranded` / `forward` / `reverse` |
| `--max_cpus` | `16` | Max CPUs per process |
| `--fc_feature_type` | `CDS` | featureCounts feature type |
| `--fc_group_by` | `locus_tag` | featureCounts attribute for grouping |
| `--fc_extra_args` | `-M --fraction` | Extra featureCounts arguments |
| `--bt2_extra_args` | `--sensitive --no-discordant -k 200` | Extra bowtie2 arguments |

## Requirements

- Nextflow ≥ 23.04
- Singularity (recommended) or Docker
