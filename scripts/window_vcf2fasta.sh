#!/bin/bash

# Goal of the script is to generate consensus fasta file for each genomic window based on a reference genome and a vcf/bcf file
# Genomic windows are split based on 'BEDtools makewindows'

# Load libraries
module load samtools
module load bcftools

# Load files and list of samples
# Change path to $windows for different genomic window sizes
ref=~/projects/def-sperling/houwaico/RawData/genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna
bcf=~/projects/def-sperling/houwaico/Choristoneura_introgression/VariantCalling/SNP_HardFilter_NoMissing_wRef.bcf
fa_dir=~/scratch/Phylogenomics/10k_test/fasta/
windows=~/scratch/Phylogenomics/10k_window.bed
mapfile -t samples < <(bcftools query -l $bcf)

# Create consensus fasta files per window per sample
while read LINE; do
    region=$(echo "$LINE" | awk '{ print $1":"$2"-"$3 }')
    name=$(echo "$LINE" | awk '{ print $4 }')
    for sample in "${samples[@]}"; do
        samtools faidx $ref "$region" | \
        bcftools consensus --sample "$sample" -I -p "$sample"\  \
        -o "$fa_dir""$sample"_"$name".fa $bcf
    done
    cat *_"$name".fa > 10k_"$name".fa
done < $windows