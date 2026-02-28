#!/bin/bash
#SBATCH --job-name=GATK_MarkDup_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 8
#SBATCH --mem-per-cpu=24G
#SBATCH -t 1-0:0:0
#SBATCH -o GATK_MarkDup_%j.out
#SBATCH -e GATK_MarkDup_%j.err
#SBATCH --array=0-4
# Change the number of arrays according to number of parallel jobs
# ${SLURM_ARRAY_TASK_ID} will correspond to the number above

module load gatk

# Set directories
inDir=~/scratch/WGS_processing/2_Alignments/
outDir="$inDir""MarkDup/"
Metrics_Dir="$inDir""MarkDup_Metrics/"
ref=~/projects/def-sperling/houwaico/RawData/genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna

mkdir -p "$outDir"
mkdir -p "$Metrics_Dir"


# Generate file lists of equal size to facilitate running bwa-mem2 in parallel
ls "$inDir"ReadGroup/*.bam > "$inDir"BAM_wRG.list
line_num=$(echo $(wc -l "$inDir"BAM_wRG.list) | awk '{ print $1 }')
line_per_array=$(("$line_num" / 5))
line_per_array_int=$(echo "($line_per_array+1.5)/1" | bc) # if the number is a float, convert to integer
split -a 1 --numeric-suffixes -l "$line_per_array_int" "$inDir"BAM_wRG.list "$inDir"BAM_wRG_
# This produces 5 equal lists of files, e.g. BAM_wRG_0, BAM_wRG_1 etc.


while read BAM; do
    name=$(basename $BAM | awk -F'_' '{ print $1 }')
    gatk --java-options "-Xmx24g" MarkDuplicates \
    -INPUT "$BAM" \
    -OUTPUT "$outDir""$name"_sorted_RG_MD.bam \
    -METRICS_FILE "$Metrics_Dir""$name"_MarkDupMetrics.txt \
    -CREATE_INDEX true \
    -TMP_DIR ~/tmp/GATK
done < "$inDir"BAM_wRG_"$SLURM_ARRAY_TASK_ID"