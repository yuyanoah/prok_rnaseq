#!/usr/bin/env python3
"""Generate summary TSV from bowtie2 log, featureCounts summary, and tpm.tsv."""

import sys
import re
import csv

def parse_bowtie2_log(path):
    total = mapped = 0
    with open(path) as f:
        text = f.read()
    m = re.search(r'(\d+) reads; of these:', text)
    if m:
        total = int(m.group(1))
    m = re.search(r'(\d+) \([\d.]+%\) aligned (?:concordantly )?exactly 1 time', text)
    if m:
        mapped += int(m.group(1))
    m = re.search(r'(\d+) \([\d.]+%\) aligned (?:concordantly )?>1 times', text)
    if m:
        mapped += int(m.group(1))
    # single-end fallback
    if mapped == 0:
        m = re.search(r'(\d+) \([\d.]+%\) aligned exactly 1 time', text)
        if m:
            mapped += int(m.group(1))
        m = re.search(r'(\d+) \([\d.]+%\) aligned >1 times', text)
        if m:
            mapped += int(m.group(1))
    rate = round(mapped / total * 100, 2) if total > 0 else 0.0
    return total, mapped, rate

def parse_fc_summary(path):
    counts = {}
    with open(path) as f:
        reader = csv.DictReader(f, delimiter='\t')
        # columns: Status, <bam_file>
        val_col = [c for c in reader.fieldnames if c != 'Status'][0]
        for row in reader:
            counts[row['Status']] = int(row[val_col])
    assigned            = counts.get('Assigned', 0)
    no_feature          = counts.get('Unassigned_NoFeatures', 0)
    ambiguity           = counts.get('Unassigned_Ambiguity', 0)
    return assigned, no_feature, ambiguity

def parse_tpm(path):
    gt0 = ge1 = 0
    with open(path) as f:
        reader = csv.DictReader(f, delimiter='\t')
        sample_cols = [c for c in reader.fieldnames if c not in ('gene_id', 'length')]
        for row in reader:
            tpm = sum(float(row[c]) for c in sample_cols) / len(sample_cols)
            if tpm > 0:
                gt0 += 1
            if tpm >= 1:
                ge1 += 1
    return gt0, ge1

def main():
    if len(sys.argv) != 5:
        sys.exit("Usage: make_summary.py <sample> <bowtie2.log> <featureCounts.summary> <tpm.tsv>")

    sample, bt2_log, fc_summary, tpm_tsv = sys.argv[1:]

    total, mapped, map_rate        = parse_bowtie2_log(bt2_log)
    assigned, no_feat, ambig       = parse_fc_summary(fc_summary)
    assign_rate = round(assigned / total * 100, 2) if total > 0 else 0.0
    genes_gt0, genes_ge1           = parse_tpm(tpm_tsv)

    header = [
        'sample', 'total_reads', 'mapped_reads', 'mapping_rate_pct',
        'assigned_reads', 'assignment_rate_pct',
        'unassigned_no_feature', 'unassigned_ambiguity',
        'genes_tpm_gt0', 'genes_tpm_ge1'
    ]
    row = [
        sample, total, mapped, map_rate,
        assigned, assign_rate,
        no_feat, ambig,
        genes_gt0, genes_ge1
    ]

    writer = csv.writer(sys.stdout, delimiter='\t')
    writer.writerow(header)
    writer.writerow(row)

if __name__ == '__main__':
    main()
