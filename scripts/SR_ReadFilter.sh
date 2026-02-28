#!/bin/bash
#SBATCH --job-name=SR_ReadFilter_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 12
#SBATCH --mem=48G
#SBATCH -t 1-0:0:0
#SBATCH -o SR_ReadFilter_%j.out
#SBATCH -e SR_ReadFilter_%j.err

module load fastp

#inDir=~/scratch/RawData/ShortReadSequences
fastq_list=~/projects/def-sperling/SBW_data/2026_BC_GSC/SBW_list.txt 
# Used ls to output a list of fastq files and removed irrelevant files. 
# Alternatively switch the while loop out for a for loop
outDir=~/scratch/WGS_processing/1_FilteredReads/
mkdir -p "$outDir"
mkdir -p "$outDir"Unpaired
mkdir -p "$outDir"Filtered
mkdir -p "$outDir"Failed
mkdir -p "$outDir"Html_report
mkdir -p "$outDir"Json_report

# filter single-end sequences
#for seq in $inDir/s_*
#do
#echo "Processing" $seq
#name=$(echo "$seq" | awk -F'/' '{ print $NF }')
#fastp -i $seq -o ${outDir}/${name}_fastp.fastq \
#--failed_out ${outDir}/${name}_filtered.fastq.gz \
#-w 4 -q 20 -u 20 -l 50 \
#-h ${outDir}/${name}_fastp.html -j ${outDir}/${name}_fastp.json
#done

# Filter paired-end sequences
# First separated out the prefix of the filename to process both R1 and R2 together
#for seq in $inDir/C-*R1.fastq
while read seq; do
    name=$(echo "$seq" | awk -F'/' '{ print $NF }' | awk -F'_' '{ print $1 }') # Extract sample name out of file name e.g. 9932_1.fastq = 9932
    seq2="${seq//_1.fastq.gz/_2.fastq.gz}"
    echo "Processing" "$name"
    fastp -i "$seq" -I "$seq2" -o "$outDir"Filtered/"$name"_1_fastp.fastq.gz -O "$outDir"Filtered/"$name"_2_fastp.fastq.gz \
    --unpaired1 "$outDir"Unpaired/"$name"_unpaired.fastq.gz --unpaired2 "$outDir"Unpaired/"$name"_unpaired.fastq.gz \
    --failed_out "$outDir"Failed/"$name"_filtered.fastq.gz \
    -w 12 -q 20 -l 50 -g -2 \
    -h "$outDir"Html_report/"$name"_fastp.html -j "$outDir"Json_report/"$name"_fastp.json
done < <(grep '_1.fastq.gz' "$fastq_list") # grep prevents fastp from looping over read 2s as well