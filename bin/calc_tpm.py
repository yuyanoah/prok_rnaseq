#!/usr/bin/env python3
"""Calculate TPM from featureCounts output.

Usage: calc_tpm.py featureCounts.txt tpm.tsv
"""

import sys
import pandas as pd
import numpy as np

def calc_tpm(counts_file, out_file):
    # featureCounts output: first 6 cols are Geneid,Chr,Start,End,Strand,Length
    # then one column per BAM file
    raw = pd.read_csv(counts_file, sep="\t", comment="#")

    meta_cols = ["Geneid", "Chr", "Start", "End", "Strand", "Length"]
    sample_cols = [c for c in raw.columns if c not in meta_cols]

    gene_ids = raw["Geneid"].values
    lengths  = raw["Length"].values          # bp
    counts   = raw[sample_cols].values.astype(float)

    # TPM = (count / length_kb) / sum(count / length_kb) * 1e6
    rpk    = counts / (lengths[:, None] / 1e3)
    tpm    = rpk / rpk.sum(axis=0) * 1e6

    # Clean sample names: strip path and suffix added by featureCounts
    clean_cols = [c.split("/")[-1].replace(".sorted.bam", "").replace(".bam", "")
                  for c in sample_cols]

    out = pd.DataFrame(tpm, columns=clean_cols)
    out.insert(0, "gene_id", gene_ids)
    out.insert(1, "length", lengths)

    out.to_csv(out_file, sep="\t", index=False, float_format="%.6f")
    print(f"TPM written to {out_file}  ({len(out)} genes, {len(clean_cols)} samples)")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Usage: calc_tpm.py featureCounts.txt tpm.tsv")
    calc_tpm(sys.argv[1], sys.argv[2])
