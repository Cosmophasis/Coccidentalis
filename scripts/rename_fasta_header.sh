#!/bin/bash

fa_list=~/scratch/Phylogenomics/100k_test/fasta_sorted.txt
fa_dir=~/scratch/Phylogenomics/100k_test/fasta/

cd "$fa_dir"

while read LINE; do
    sed -i 's/CM0/ CM0/g' "$LINE"
done < "$fa_list"