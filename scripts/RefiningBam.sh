#!/bin/bash
#SBATCH --job-name=RefiningBam_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 8
#SBATCH --mem-per-cpu=24G
#SBATCH -t 1-0:0:0
#SBATCH -o RefiningBam_%j.out
#SBATCH -e RefiningBam_%j.err
#SBATCH --array=0-4
# Change the number of arrays according to number of parallel jobs
# ${SLURM_ARRAY_TASK_ID} will correspond to the number above


# This file does quite a few things
# 1. Generate uBAM from filtered fastq file (hence adapters do not need to be marked)
# 2. Merge uBAM with aligned BAM generated from another step
# 3. Mark duplicate reads


module load gatk

# Set directories
uBAM_Dir=~/scratch/WGS_processing/
Align_Dir=~/scratch/WGS_processing/2_Alignments/
outDir="$Align_Dir""Refined_BAM/"
ref=~/projects/def-sperling/houwaico/RawData/genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna

mkdir -p "$outDir"


# Generate file lists of equal size to facilitate running bwa-mem2 in parallel
#ls "$readDir" > "$outDir"filtered_fastq.list
#wc_output=$(wc -l "$outDir"filtered_fastq.list)
#line_num=$(echo "$wc_output" | awk ' {print $1} ')
#line_per_array=$(("$line_num" / 5))
#line_per_array_int=$(echo "($line_per_array+1.5)/1" | bc) # if the number is a float, convert to integer
#split -a 1 --numeric-suffixes -l "$line_per_array_int" "$outDir"filtered_fastq.list "$outDir"filtered_fastq_
# This produces 5 equal lists of files, e.g. filtered_fastq_1, filtered_fastq_2 etc.
# The files were already created from SR_Align_SBW.sh


while read fastq1; do
    name=$(basename "$fastq1" | awk -F'_' '{ print $1 }')
    fastq2="${fastq1//_1_fastp.fastq.gz/_2_fastp.fastq.gz}"
    index=$(zcat "$fastq1" | head -n 1 | awk -F':' '{ print $NF }')
    gatk --java-options "-Xmx24G" FastqToSam \
    -FASTQ "$fastq1" \
    -FASTQ2 "$fastq2" \
    -OUTPUT /dev/stdout \
    -READ_GROUP_NAME 23G723LT4.8 \
    -SAMPLE_NAME "$name" \
    -LIBRARY_NAME PX3836 \
    -PLATFORM_UNIT 23G723LT4."$index".8 \
    -PLATFORM illumina \
    -SEQUENCING_CENTER BCGSC \
    -TMP_DIR ~/tmp/GATK | \
    gatk --java-options "-Xmx24G" MergeBamAlignment \
    -ALIGNED_BAM "$Align_Dir""$name"_sorted.bam \
    -UNMAPPED_BAM /dev/stdin \
    -OUTPUT /dev/stdout \
    -R "$ref" \
    -TMP_DIR ~/tmp/GATK | \
    gatk --java-options "-Xmx24G" MarkDuplicates
done < <(grep '_1_fastp.fastq.gz' "$Align_Dir"filtered_fastq_"$SLURM_ARRAY_TASK_ID") 
# array lists stored in $Align_Dir