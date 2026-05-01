#!/usr/bin/env python3
"""Convert Prodigal GFF to proper GFF3 with gene/CDS hierarchy and locus_tag.

Prodigal emits minimal GFF with ID= but no locus_tag= and no parent gene
features, which featureCounts requires when grouping by locus_tag.

Usage: prodigal_gff2gff3.py input.gff > output.gff3
"""

import sys
import re

def main():
    if len(sys.argv) != 2:
        sys.exit("Usage: prodigal_gff2gff3.py input.gff")

    out = []
    out.append("##gff-version 3")

    with open(sys.argv[1]) as fh:
        for line in fh:
            line = line.rstrip("\n")
            if line.startswith("#"):
                if not line.startswith("##gff-version"):
                    out.append(line)
                continue

            parts = line.split("\t")
            if len(parts) != 9:
                continue

            seqid, source, feat_type, start, end, score, strand, phase, attrs = parts
            if feat_type != "CDS":
                continue

            # Extract ID
            m = re.search(r'\bID=([^;]+)', attrs)
            id_val = m.group(1) if m else f"{seqid}_{start}_{end}"

            # Build locus_tag preserving dots to match Prodigal faa/ffn naming
            # (e.g. NZ_CP022466.1_1). Prodigal sometimes emits bare contig-index
            # IDs like "1_1" instead of full IDs like "NZ_CP022466.1_1"; in that
            # case strip the contig-index prefix and prepend the actual seqid.
            if id_val.startswith(seqid):
                locus_tag = id_val          # already seqid-prefixed: NZ_CP022466.1_1
            else:
                norm_id   = re.sub(r'[^A-Za-z0-9_]', '_', id_val)
                gene_part = norm_id.split('_', 1)[1] if '_' in norm_id else norm_id
                locus_tag = f"{seqid}_{gene_part}"   # e.g. NZ_CP022466.1_1

            # Collect extra attributes (drop ID= so we can rebuild it)
            extra_attrs = re.sub(r'\bID=[^;]*(;|$)', '', attrs).strip(';')

            gene_id    = f"gene_{locus_tag}"
            gene_attr  = f"ID={gene_id};locus_tag={locus_tag}"
            cds_attr   = f"ID={locus_tag};Parent={gene_id};locus_tag={locus_tag}"
            if extra_attrs:
                cds_attr += f";{extra_attrs}"

            out.append("\t".join([seqid, source, "gene",  start, end, score, strand, ".", gene_attr]))
            out.append("\t".join([seqid, source, "CDS",   start, end, score, strand, phase, cds_attr]))

    print("\n".join(out))

if __name__ == "__main__":
    main()
