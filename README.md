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

## Quick Start

**1. Load Nextflow**
```bash
module load nextflow
```

**2. Pull the pipeline**
```bash
nextflow pull yuyanoah/prok_rnaseq
```

To update to the latest version later:
```bash
nextflow pull yuyanoah/prok_rnaseq
```

**3. Run**

See [Usage](#usage) below.

> **Note for SLURM clusters with limited home quota** (e.g. SCG):
> Set the following before running to redirect Nextflow and Singularity cache to a high-capacity filesystem:
> ```bash
> export NXF_HOME=/path/to/storage/.nextflow
> export NXF_SINGULARITY_CACHEDIR=/path/to/storage/.singularity
> export SINGULARITY_CACHEDIR=/path/to/storage/.singularity/cache
> export SINGULARITY_TMPDIR=/path/to/storage/.singularity/tmp
> ```
> Add these to `~/.bashrc` to make them permanent.

---

## Usage

Paired-end:
```bash
nextflow run yuyanoah/prok_rnaseq \
    -profile slurm,singularity \
    --r1           sample_R1.fastq.gz \
    --r2           sample_R2.fastq.gz \
    --fasta        genome.fasta \
    --gff          genome.gff \
    --outdir       results \
    --strandedness unstranded \
    --max_cpus     16
```

Single-end:
```bash
nextflow run yuyanoah/prok_rnaseq \
    -profile slurm,singularity \
    --r1           sample.fastq.gz \
    --fasta        genome.fasta \
    --gff          genome.gff \
    --outdir       results \
    --strandedness unstranded \
    --max_cpus     16
```

## Input

| Parameter | Description |
|-----------|-------------|
| `--r1` | R1 (or single-end) FASTQ (.fastq.gz) |
| `--r2` | R2 FASTQ (.fastq.gz) — omit for single-end |
| `--fasta` | Reference genome FASTA |
| `--gff` | Reference annotation GFF/GFF3 (Prodigal or Bakta — auto-detected) |
| `--outdir` | Output directory |

Sample name is derived automatically from the R1 filename. Override with `--sample`.

**GFF format** — both Prodigal and Bakta are accepted; format is auto-detected.

## Output

| Path | Description |
|------|-------------|
| `bam/` | Sorted BAM files |
| `featurecounts/` | featureCounts output |
| `tpm/tpm.tsv` | TPM table (genes × samples) |
| `summary/summary.tsv` | Mapping rate, assignment rate, genes detected |
| `gff/` | Prepared GFF3 |

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--sample` | *(derived from R1 filename)* | Sample name |
| `--strandedness` | `unstranded` | `unstranded` / `forward` / `reverse` |
| `--max_cpus` | `16` | Max CPUs per process |
| `--fc_feature_type` | `CDS` | featureCounts feature type |
| `--fc_group_by` | `locus_tag` | featureCounts attribute for grouping |
| `--fc_extra_args` | `-M --fraction` | Extra featureCounts arguments |
| `--bt2_extra_args` | `--sensitive --no-discordant -k 200` | Extra bowtie2 arguments |

## Requirements

- Nextflow ≥ 23.04
- Singularity (recommended) or Docker
