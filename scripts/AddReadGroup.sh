#!/bin/bash

module load gatk

inDir=~/scratch/WGS_processing/2_Alignments/BAM/
fastq_Dir=~/scratch/WGS_processing/1_FilteredReads/Filtered/
outDir=~/scratch/WGS_processing/2_Alignments/ReadGroup/

mkdir -p "$outDir"


for bam in "$inDir"*_sorted.bam; do
    echo "Adding read group heading to ""$bam"
    name=$(basename $bam | awk -F"_" '{ print $1 }')
    fastq="$fastq_Dir""$name""_1_fastp.fastq.gz"
    index=$(zcat "$fastq" | head -n 1 | awk -F':' '{ print $NF }')
    gatk --java-options "-Xmx24g" AddOrReplaceReadGroups \
    -I "$bam" -O "$outDir""$name"_sorted_RG.bam \
    -PL ILLUMINA -PM NovaSeqX \
    -SM "$name" -LB PX3836 -ID 23G723LT4.8 -PU 23G723LT4.8."$index" \
    &> "$outDir""$name"_AddOrReplaceReadGroups.out
done