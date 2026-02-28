#!/bin/bash

module load r

vcf_dir=~/scratch/Phylogenomics/50SNPs_test/vcf/
out_dir=~/scratch/Phylogenomics/50SNPs_test/fasta/

cd "$out_dir" || exit

while read LINE; do
    Rscript ~/software/TopoWindows/Topo_windows_v04_cl_wrapper.R \
    --vcf "$LINE" --window_type s --size 50 --incr 0 --phased F --prefix 50SNPs_CM046131.1 --ali T --tree N --force T
done < <(ls "$vcf_dir"*.vcf.gz)