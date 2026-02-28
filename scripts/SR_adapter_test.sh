#!/bin/bash
#SBATCH --job-name=SR_AdapterSearch_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH -t 3:0:0
#SBATCH -o SR_AdapterSearch_%j.out
#SBATCH -e SR_AdapterSearch_%j.out

module load fastp

mkdir -p ~/scratch/ProcessedShortReadSeq

outDir=~/scratch/ProcessedShortReadSeq

echo "Running fastp with automatic detection."
date +'%T'

#Check for adapters with fastp
seq=${outDir}/C-occidentalis_R1.fastq_fastp.fastq
name=$(echo "$seq" | awk -F'/' '{ print $NF }' | awk -F'_' '{ print $1 }')
seq2=$(echo "$seq" | awk -F'_' '{ print $1 "_R2.fastq_fastp.fastq" }')
echo "Processing" ${name}
fastp -i $seq -I $seq2 -o ${outDir}/${name}_R1_adapter1.fastq -O ${outDir}/${name}_R2_adapter2.fastq \
-w 4 -q 20 -u 20 --detect_adapter_for_pe \
-h ${outDir}/${name}_adapter1_fastp.html -j ${outDir}/${name}_adapter1_fastp.json

echo "Running fastp with automatic detection and fasta file."
date +'%T'
fasta=~/scratch/ProcessedShortReadSeq/nextera.fasta

seq=${outDir}/C-occidentalis_R1.fastq_fastp.fastq
name=$(echo "$seq" | awk -F'/' '{ print $NF }' | awk -F'_' '{ print $1 }')
seq2=$(echo "$seq" | awk -F'_' '{ print $1 "_R2.fastq_fastp.fastq" }')
echo "Processing" ${name}
fastp -i $seq -I $seq2 -o ${outDir}/${name}_R1_adapter2.fastq -O ${outDir}/${name}_R2_adapter3.fastq \
-w 4 -q 20 -u 20 -2 --adapter_fasta=$fasta \
-h ${outDir}/${name}_adapter2_fastp.html -j ${outDir}/${name}_adapter2_fastp.json