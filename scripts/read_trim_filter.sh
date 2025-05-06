#!/bin/bash
#SBATCH --job-name=read_trim_filter_$j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --mem=8G
#SBATCH -t 02:00:00
#SBATCH -o read_trim_filter_%j.out
#SBATCH -e read_trim_filter_%j.err

module load fastp

outdir=~/scratch/LinkageCohortsTest/ProcessedReads/

# Use cutadapt to trim the complexity reduction primer (12bp; Sonah et al., 2013), then filter for quality and length in fastp, generating the html/json reports.

for file in ${outdir}*_cut.fastq
do
echo "Processing" $file
fastp -i $file -o ${file}_fastp2.fastq \
-w 4 -q 20 -u 20 -l 25 \
-h ${file}_fastp2.html -j ${file}_fastp2.json
done
