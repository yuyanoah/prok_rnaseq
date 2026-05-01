#!/usr/bin/env python3
"""Calculate TPM from featureCounts output (stdlib only).

Usage: calc_tpm.py featureCounts.txt tpm.tsv
"""

import sys
import csv

def calc_tpm(counts_file, out_file):
    with open(counts_file) as f:
        lines = [l for l in f if not l.startswith('#')]

    reader = csv.DictReader(iter(lines), delimiter='\t')
    rows = list(reader)
    if not rows:
        sys.exit("No data rows found in " + counts_file)

    meta_cols = {'Geneid', 'Chr', 'Start', 'End', 'Strand', 'Length'}
    sample_cols = [c for c in reader.fieldnames if c not in meta_cols]

    gene_ids = [r['Geneid'] for r in rows]
    lengths  = [int(r['Length']) for r in rows]

    # Clean sample names: strip path and BAM suffix
    clean_cols = [c.split('/')[-1].replace('.sorted.bam', '').replace('.bam', '')
                  for c in sample_cols]

    tpm_matrix = []
    for col in sample_cols:
        counts = [float(r[col]) for r in rows]
        rpk    = [c / (l / 1000.0) for c, l in zip(counts, lengths)]
        total  = sum(rpk)
        tpm    = [r / total * 1e6 if total > 0 else 0.0 for r in rpk]
        tpm_matrix.append(tpm)

    with open(out_file, 'w', newline='') as f:
        writer = csv.writer(f, delimiter='\t')
        writer.writerow(['gene_id', 'length'] + clean_cols)
        for i in range(len(gene_ids)):
            row = [gene_ids[i], lengths[i]] + [f"{tpm_matrix[j][i]:.6f}" for j in range(len(sample_cols))]
            writer.writerow(row)

    print(f"TPM written to {out_file}  ({len(rows)} genes, {len(clean_cols)} samples)")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit("Usage: calc_tpm.py featureCounts.txt tpm.tsv")
    calc_tpm(sys.argv[1], sys.argv[2])
