#!/bin/bash
#SBATCH --job-name=MitoFinder_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 40
#SBATCH --mem=160G
#SBATCH -t 3-0:0:0
#SBATCH -o MitoFinder_%j.out
#SBATCH -e MitoFinder_%j.err
#SBATCH --array=0-9
    # Change the number of arrays according to number of parallel jobs
    # ${SLURM_ARRAY_TASK_ID} will correspond to the number above


module load apptainer


inDir=~/scratch/WGS_processing/1_FilteredReads/Filtered/
inDir1=~/projects/def-sperling/houwaico/Choristoneura_introgression/ProcessedShortReadSeq/
genbank=~/projects/def-sperling/houwaico/RawData/genome/Cfum_mt.gb
outDir=~/scratch/MitoFinder_megahit/

mkdir -p "$outDir"

memory_in_G="160" # MitoFinder breaks when a letter is included (e.g. 160G)


# Create list of fastq files to iterate over
fqlist="$outDir"fastq.list
if [ ! -f "$fqlist" ]; then
    ls "$inDir"*_1_fastp.fastq.gz > "$fqlist"
    ls "$inDir1"*R1.fastq_fastp.fastq >> "$fqlist"
    ls "$inDir1"s*filtered.fastq.gz >> "$fqlist"
else
    echo "fastq list found."
fi


# Generate file lists of equal size to facilitate running bwa-mem2 in parallel
if [ ! -f "$outDir""fastq_0" ]; then
    line_num=$(wc -l "$fqlist" | awk '{ print $1 }')
    line_per_array=$(("$line_num" / 10))
    line_per_array_int=$(echo "($line_per_array+1.5)/1" | bc) # if the number is a float, convert to integer
    split -a 1 --numeric-suffixes -l "$line_per_array_int" "$fqlist" "$outDir"fastq_
else
    echo "Split fastq lists for array job found."
fi
# This produces 10 equal lists of files, e.g. fastq_0, fastq_1 etc.


# Saving regex patterns for proceeding if statements
regex1="^[0-9+.*]"                         # Matching BC GSC reads
regex2="^C-.+R1\.fastq_fastp\.fastq"       # Matching old paired-end reads
regex3="^s_[0-9].+_fastp\.fastq"           # Matching old single-end reads

cd "$outDir" || exit # Mitofinder outputs files directly in wd

# Run MitoFinder in a loop
while read fastq; do
    if [[ $(basename "$fastq") =~ $regex1 ]]; then
        name=$(basename "$fastq" | awk -F'_' '{ print $1 }')
        if [ -d "$outDir""$name" ]; then # Skip the sample if a MitoFinder run is found
            echo "A MitoFinder run for ""$name"" already exists. Skipped"
            continue
        fi
        fastq2="${fastq//_1.fastq.gz/_2.fastq.gz}"
        apptainer run ~/tmp/mitofinder_v1.4.2.sif \
        --megahit -j "$name" \
        -1 "$fastq" -2 "$fastq2" -r "$genbank" -o 5 \
        -p "$SLURM_CPUS_ON_NODE" -m "$memory_in_G"
    elif [[ $(basename "$fastq") =~ $regex2 ]]; then
        name=$(basename "$fastq" | awk -F'_' '{ print $1 }')
        if [ -d "$outDir""$name" ]; then # Skip the sample if a MitoFinder run is found
            echo "A MitoFinder run for ""$name"" already exists. Skipped"
            continue
        fi
        fastq2="${fastq//_R1.fastq_fastp.fastq/_R2.fastq_fastp.fastq}"
        apptainer run ~/tmp/mitofinder_v1.4.2.sif \
        --megahit -j "$name" \
        -1 "$fastq" -2 "$fastq2" -r "$genbank" -o 5 \
        -p "$SLURM_CPUS_ON_NODE" -m "$memory_in_G"
    elif [[ $(basename "$fastq") =~ $regex3 ]]; then
        name=$(basename "$fastq" | awk -F'_' '{ print $1$2$3 }')
        if [ -d "$outDir""$name" ]; then # Skip the sample if a MitoFinder run is found
            echo "A MitoFinder run for ""$name"" already exists. Skipped"
            continue
        fi
        apptainer run ~/tmp/mitofinder_v1.4.2.sif \
        --megahit -j "$name" \
        -s "$fastq" -r "$genbank" -o 5 \
        -p "$SLURM_CPUS_ON_NODE" -m "$memory_in_G"
    else
        echo "$fastq"" is not a recognized .fastq file"
    fi 
done < "$outDir"fastq_"$SLURM_ARRAY_TASK_ID"