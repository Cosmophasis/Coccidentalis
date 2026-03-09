#!/bin/bash

module load seqkit

inDir=~/scratch/MitoFinder_megahit/
outDir=~/scratch/Mitogenome_analysis/

mkdir -p $outDir
mkdir -p "$outDir""gene_fasta/"


falist="$outDir"final_genes.list
if [ ! -f $falist ]; then
    find "$inDir" -name '*final_genes_NT.fasta' > "$outDir"final_genes.list
fi


declare -a \
mt_genes=("ATP8" "COX2" "COX3" "CYTB" "COX1" "ATP6" "rrnL" "rrnS" "ND4L" "ND1" "ND3" "ND2" "ND5" "ND4" "ND6") 

for gene in "${mt_genes[@]}"; do
    while read file; do
        seqkit grep -r -p "$gene"'$' "$file" >> "$outDir""gene_fasta/""$gene"".fasta"
    done < "$outDir"final_genes.list
    cat "$outDir""gene_fasta/""$gene"".fasta" | seqkit rmdup -n -o "$outDir""gene_fasta/""$gene""_rmdup.fa.gz"
done
