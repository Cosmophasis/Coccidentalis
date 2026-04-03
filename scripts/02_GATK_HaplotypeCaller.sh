#!/bin/bash
#SBATCH --job-name=GATK_HaplotypeCaller_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 8
#SBATCH --mem=8G
#SBATCH -t 2-0:0:0
#SBATCH -o GATK_HaplotypeCaller_%j.out
#SBATCH -e GATK_HaplotypeCaller_%j.out
#SBATCH --array=1-43
# Change the number of arrays according to number of parallel jobs
# "$SLURM_ARRAY_TASK_ID" will correspond to the number above


# Load modules
module load gatk


# Set variables
outDir=~/scratch/WGS_processing/GVCF/
ref=~/projects/def-sperling/houwaico/RawData/genome/GCF_025370935.1_NRCan_CFum_1_genomic.fna
bamList=~/tmp/bam.list


# Set up array
bam_1=$((2*"$SLURM_ARRAY_TASK_ID"-1))
bam_2=$((2*"$SLURM_ARRAY_TASK_ID"))
declare -a bam_array=($(awk -v num="$bam_1" 'NR == num' $bamList) $(awk -v num="$bam_2" 'NR == num' $bamList))


# Run HaplotypeCaller
for bam in "${bam_array[@]}"; do
    name=$(basename "$bam" | awk -F'_' '{ print $1 }')
    gatk HaplotypeCaller --native-pair-hmm-threads "$SLURM_CPUS_PER_TASK" \
    -I $bam -O "$outDir""$name".g.vcf.gz \
    -R $ref -ERC GVCF \
    --tmp-dir "$SLURM_TMPDIR"
done