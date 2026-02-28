#!/bin/bash
#SBATCH --job-name=window_IQtree_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 12
#SBATCH --mem=48G
#SBATCH -t 1-0:0:0
#SBATCH --array=0-4
# Change the number of arrays according to number of parallel jobs
# ${SLURM_ARRAY_TASK_ID} will correspond to the number above

module load iq-tree

dir=~/scratch/Phylogenomics/100k_test/
fa_dir="$dir"fasta/
tree_dir="$dir"tree/
fasta_list=~/scratch/Phylogenomics/100k_test/fasta_sorted.txt
# Fasta files that were filtered for variants

# Generate file lists of equal size to facilitate running IQTREE in parallel
wc_output=$(wc -l "$fasta_list")
line_num=$(echo "$wc_output" | awk ' {print $1} ')
line_per_array=$(("$line_num" / 5))
line_per_array_int=$(echo "($line_per_array+1.5)/1" | bc) # if the number is a float, convert to integer
split -a 1 --numeric-suffixes -l "$line_per_array_int" "$fasta_list" "$dir"fasta_sorted_
# This produces 5 equal lists of files, e.g. fasta_sorted_1, fasta_sorted_2 etc.

# Designate a list of files for each array
fa_list="$dir"fasta_sorted_"$SLURM_ARRAY_TASK_ID"

# For each file in the list, run IQTREE2
# --abayes to compute per branch support for wASTRAL
while read LINE; do
    fa_file=$(echo "$LINE" | awk -F/ ' {print $2} ')
    iqtree2 -s "$fa_dir""$fa_file" --prefix "$tree_dir""$fa_file" \
    -T 12 -m MFP --abayes
done < "$fa_list"