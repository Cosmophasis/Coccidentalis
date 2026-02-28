#!/bin/bash

module load gatk

# Set directories
inDir=~/scratch/WGS_processing/1_FilteredReads/Filtered/
outDir=~/scratch/WGS_processing/1a_RawMetadata/
logs=~/scratch/logs/

mkdir -p "$outDir"

# For loop to create uBAM for fastq files from 2026 BC GSC sequencing run

for fastq1 in "$inDir"*_1_fastp.fastq.gz; do
    name=$(basename "$fastq1" | awk -F'_' '{ print $1 }')
    fastq2="${fastq1//_1_fastp.fastq.gz/_2_fastp.fastq.gz}"
    index=$(zcat "$fastq1" | head -n 1 | awk -F':' '{ print $NF }')
    gatk --java-options "-Xmx24G" FastqToSam \
    -FASTQ "$fastq1" \
    -FASTQ2 "$fastq2" \
    -OUTPUT "$outDir""$name"_fastqtosam.bam \
    -READ_GROUP_NAME 23G723LT4.8 \
    -SAMPLE_NAME "$name" \
    -LIBRARY_NAME PX3836 \
    -PLATFORM_UNIT 23G723LT4."$index".8 \
    -PLATFORM illumina \
    -SEQUENCING_CENTER BCGSC &> "$logs""$name"_fastqtosam.out
done