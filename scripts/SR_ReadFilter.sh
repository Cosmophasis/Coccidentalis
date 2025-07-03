#!/bin/bash
#SBATCH --job-name=SR_ReadFilter_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH -t 3:0:0
#SBATCH -o SR_ReadFilter_%j.out
#SBATCH -e SR_ReadFilter_%j.err

module load fastp

mkdir -p ~/scratch/ProcessedShortReadSeq

inDir=~/scratch/RawData/ShortReadSequences
outDir=~/scratch/ProcessedShortReadSeq

# filter single-end sequences
for seq in $inDir/s_*
do
echo "Processing" $seq
name=$(echo "$seq" | awk -F'/' '{ print $NF }')
fastp -i $seq -o ${outDir}/${name}_fastp.fastq \
--failed_out ${outDir}/${name}_filtered.fastq.gz \
-w 4 -q 20 -u 20 -l 50 \
-h ${outDir}/${name}_fastp.html -j ${outDir}/${name}_fastp.json
done

# Filter paired-end sequences
# First separated out the prefix of the filename to process both R1 and R2 together
for seq in $inDir/C-*R1.fastq
do
name=$(echo "$seq" | awk -F'/' '{ print $NF }' | awk -F'_' '{ print $1 }')
seq2=$(echo "$seq" | awk -F'_' '{ print $1 "_R2.fastq" }')
echo "Processing" ${name}
fastp -i $seq -I $seq2 -o ${outDir}/${name}_R1.fastq_fastp.fastq -O ${outDir}/${name}_R2.fastq_fastp.fastq \
--unpaired1 ${outDir}/${name}_unpaired.fastq.gz --unpaired2 ${outDir}/${name}_unpaired.fastq.gz \
--failed_out ${outDir}/${name}_filtered.fastq.gz \
-w 4 -q 20 -u 20 -l 50 \
-h ${outDir}/${name}_fastp.html -j ${outDir}/${name}_fastp.json
done