#!/bin/bash
#SBATCH --job-name=SR_Align_SBW_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 12
#SBATCH --mem=36G
#SBATCH -t 48:0:0
#SBATCH -o SR_Align_SBW_%j.out
#SBATCH -e SR_Align_SBW_%j.err

module load bwa-mem2
module load samtools

echo "bwa-mem2 version:"
bwa-mem2 version
echo "samtools version:"
samtools version

# Load variable of reference genome.

ref=~/scratch/RawData/Genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna.gz

# Index Choristoneura fumiferana genome, if index found the skip this step.

index=~/scratch/RawData/Genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna.gz

if [ -f "$index" ]; then
    echo "Ref. genome index found"
else
    bwa-mem2 index $ref
fi

# Aligning filtered single-end reads to the genome.

readDir=~/scratch/ProcessedShortReadSeq
samDir=~/scratch/ShortReadAlignments

mkdir -p $samDir

for seq in ${readDir}/s_*_fastp.fastq
do
    name=$(echo $seq | awk -F'/' '{ print $NF }')
    echo "Current time is:"
    date +'%F %T'
    echo "Aligning $name to CFum genome..."
    bwa-mem2 mem -t 12 $ref $seq | \
    samtools view -@ 12 -h --output-fmt=BAM --reference $ref | \
    samtools sort -@ 12 --output-fmt=BAM -m 3G --reference $ref -o ${samDir}/${name}_sorted.bam
done

echo "Current time is:"
date +'%F %T'

# Aligning filtered paired-end reads to the genome.

for seq in ${readDir}/C-*_R1.fastq_fastp.fastq
do
    name=$(echo $seq | awk -F'/' '{ print $NF }' | awk -F'_' '{ print $1 }')
    seq2=$(echo $seq | awk -F'_' '{ print $1 "_R2.fastq_fastp.fastq"}')
    echo "Aligning $name to CFum genome..."
    bwa-mem2 mem -t 12 $ref $seq $seq2 > ${samDir}/${name}.sam
    samtools view -@ 12 -h -O bam --reference $ref ${samDir}/${name}.sam | \
    samtools sort -@ 12 -O bam -m 3G -o ${samDir}/${name}_sorted.bam
done

echo "Current time is:"
date +'%F %T'