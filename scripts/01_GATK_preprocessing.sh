#!/bin/bash
#SBATCH --job-name=01_GATK_preprocessing_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 16
#SBATCH --mem-per-cpu=80G
#SBATCH -t 2-0:0:0
#SBATCH -o 01_GATK_preprocessing_%j.out
#SBATCH -e 01_GATK_preprocessing_%j.err
#SBATCH --array=0-10
    # Change the number of arrays according to number of parallel jobs
    # ${SLURM_ARRAY_TASK_ID} will correspond to the number above


# Description: The point of this pipeline is to process raw demultiplexed fastq files into BAM alignments ready for GATK variant calling

# Set variables
ref=~/projects/def-sperling/houwaico/RawData/genome/GCF_025370935.1_NRCan_CFum_1_genomic.fna
fastq_list=~/tmp/fastq_
outDir=~/scratch/WGS_processing/
export _JAVA_OPTIONS='-Xmx80g'

# Load software
module load fastp bwa-mem2 gatk


# Create directories
mkdir -p "$outDir"{Adapter_metrics,Duplicate_metrics,Cleaned_alignments}


# Create file list
#if [ ! -f "$outDir"BAM_0 ]; then
#    line_num=$(wc -l "$outDir"BAM.list | awk '{ print $1 }')
#    line_per_array=$(("$line_num" / 20))
#    line_per_array_int=$(echo "($line_per_array+1.5)/1" | bc) # if the number is a float, convert to integer
#    split -a 2 --numeric-suffixes -l "$line_per_array_int" "$outDir"BAM.list "$outDir"BAM_
#fi
# This produces 10 equal lists of files, e.g. BAM_RG_MD_0, BAM_RG_MD_1 etc.

# I manually split the fastq.list into 10 files already

job_num=$(printf "%02d" "$SLURM_ARRAY_TASK_ID") # Since number of jobs exceed 9, one more digit needed

#sleep 20 # Sometimes array jobs can't run because the list of files are not produced yet. Adding this to account for that


# Preprocessing pipeline (instead of piping, use intermediate files on SLURM_TMPDIR)
while read read1; do
    name=$(basename $read1 .fastq.gz | awk -F'_' '{ print $1 }')
    read2="${read1//_1.fastq.gz/_2.fastq.gz}"
    index=$(zcat "$read1" | head -n 1 | awk -F':' '{ print $NF }')
    date
    echo "Start pre-processing pipeline on sample ""$name"
    fastp -i "$read1" -I "$read2" -o "$SLURM_TMPDIR"/"$name"_1_fastp.fastq -O "$SLURM_TMPDIR"/"$name"_2_fastp.fastq \
    -w "$SLURM_CPUS_PER_TASK" -q 20 -l 70 -g -2
    date
    echo "Running FastqToSam on sample""$name"
    gatk FastqToSam \
    -F1 "$SLURM_TMPDIR"/"$name"_1_fastp.fastq -F2 "$SLURM_TMPDIR"/"$name"_2_fastp.fastq \
    -O "$SLURM_TMPDIR"/"$name"_unaligned.bam \
    -PL ILLUMINA -PM NovaSeqX \
    -SM "$name" -LB PX3836 -RG 23G723LT4.8 -PU 23G723LT4.8."$index" \
    --TMP_DIR "$SLURM_TMPDIR"
    date
    echo "Running MarkIlluminaAdapters on sample ""$name"
    gatk MarkIlluminaAdapters \
    -I "$SLURM_TMPDIR"/"$name"_unaligned.bam -O "$SLURM_TMPDIR"/"$name"_AdapterMarked.bam \
    -M "$outDir"Adapter_metrics/"$name"_adapterMetrics.txt \
    --TMP_DIR "$SLURM_TMPDIR"
    date
    echo "Running SamToFastq on sample ""$name"
    gatk SamToFastq \
    -I "$SLURM_TMPDIR"/"$name"_AdapterMarked.bam \
    -FASTQ "$SLURM_TMPDIR"/"$name"_SamToFastq.fastq \
    -CLIP_ATTR XT -CLIP_ACT 2 -INTERLEAVE true \
    --TMP_DIR "$SLURM_TMPDIR"
    date
    echo "Running bwa-mem2 on sample ""$name"
    bwa-mem2 mem -t "$SLURM_CPUS_PER_TASK" -pM \
    -o "$SLURM_TMPDIR"/"$name"_Aligned.bam \
    $ref "$SLURM_TMPDIR"/"$name"_SamToFastq.fastq
    date
    echo "Running MergeBAMAlignment on sample ""$name"
    gatk MergeBamAlignment \
    -ALIGNED "$SLURM_TMPDIR"/"$name"_Aligned.bam -UNMAPPED "$SLURM_TMPDIR"/"$name"_AdapterMarked.bam \
    -O "$SLURM_TMPDIR"/"$name"_MergeBAMAlignment.bam \
    -R $ref --CREATE_INDEX true --ADD_MATE_CIGAR true \
    --CLIP_ADAPTERS false --CLIP_OVERLAPPING_READS true \
    --INCLUDE_SECONDARY_ALIGNMENTS true --MAX_INSERTIONS_OR_DELETIONS -1 \
    --PRIMARY_ALIGNMENT_STRATEGY MostDistant --ATTRIBUTES_TO_RETAIN XS \
    --TMP_DIR "$SLURM_TMPDIR"
    date
    echo "Running MarkDuplicates on sample ""$name"
    gatk MarkDuplicates \
    -I "$SLURM_TMPDIR"/"$name"_MergeBAMAlignment.bam -O "$outDir"Cleaned_alignments/"$name"_clean_MD.bam \
    -M "$outDir"Duplicate_metrics/"$name"_duplicateMetrics.txt \
    --CREATE_INDEX true --TMP_DIR "$SLURM_TMPDIR"
    date
    rm "$SLURM_TMPDIR"/"$name"_*
done < "$fastq_list""$job_num"