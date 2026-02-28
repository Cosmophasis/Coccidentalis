#!/bin/bash
#SBATCH --job-name=SR_Align_SBW_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 12
#SBATCH --mem-per-cpu=8G
#SBATCH -t 2-0:0:0
#SBATCH -o SR_Align_SBW_%j.out
#SBATCH -e SR_Align_SBW_%j.err
#SBATCH --array=0-4
# Change the number of arrays according to number of parallel jobs
# ${SLURM_ARRAY_TASK_ID} will correspond to the number above

module load bwa-mem2
module load samtools

echo "bwa-mem2 version:" # not very necessary
bwa-mem2 version
echo "samtools version:"
samtools version

# Load variable of reference genome.

ref=~/projects/def-sperling/houwaico/RawData/genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna
# ref genome has to be indexed with 
# bwa-mem2 index $ref

# Aligning filtered single-end reads to the genome.

readDir=~/scratch/WGS_processing/1_FilteredReads/Filtered/
outDir=~/scratch/WGS_processing/2_Alignments/

mkdir -p $outDir
mkdir -p "$outDir"SAM
mkdir -p "$outDir"BAM

# Generate file lists of equal size to facilitate running bwa-mem2 in parallel
ls "$readDir" > "$outDir"filtered_fastq.list
wc_output=$(wc -l "$outDir"filtered_fastq.list)
line_num=$(echo "$wc_output" | awk ' {print $1} ')
line_per_array=$(("$line_num" / 5))
line_per_array_int=$(echo "($line_per_array+1.5)/1" | bc) # if the number is a float, convert to integer
split -a 1 --numeric-suffixes -l "$line_per_array_int" "$outDir"filtered_fastq.list "$outDir"filtered_fastq_
# This produces 5 equal lists of files, e.g. filtered_fastq_1, filtered_fastq_2 etc.

#for seq in ${readDir}/s_*_fastp.fastq
#do
#    name=$(echo $seq | awk -F'/' '{ print $NF }')
#   echo "Current time is:"
#    date +'%F %T'
#    echo "Aligning $name to CFum genome..."
#    bwa-mem2 mem -t 12 $ref $seq | \
#    samtools view -@ 12 -h --output-fmt=BAM --reference $ref | \
#    samtools sort -@ 12 --output-fmt=BAM -m 3G --reference $ref -o ${samDir}/${name}_sorted.bam
#done

#echo "Current time is:"
#date +'%F %T'

# Aligning filtered paired-end reads to the genome.

while read seq; do
    name=$(echo $seq | awk -F'_' '{ print $1 }')
    seq2="$name""_2_fastp.fastq.gz"
    echo "Aligning $name to CFum genome..."
    echo "Current time is:"
    date +'%F %T'
    bwa-mem2 mem -t 12 $ref "$readDir""$seq" "$readDir""$seq2" | \
    samtools view -@ 12 -h -O bam --reference $ref | \
    samtools sort -@ 12 -O bam -m 8G -o "$outDir"BAM/"$name"_sorted.bam # can be very memory hungry
    echo "Current time is:"
    date +'%F %T'
done < <(grep '_1' "$outDir"filtered_fastq_"$SLURM_ARRAY_TASK_ID")