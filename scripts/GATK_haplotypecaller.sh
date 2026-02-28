#!/bin/bash
#SBATCH --job-name=GATK_haplotypecaller_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 16
#SBATCH --mem-per-cpu=6G
#SBATCH -t 5-0:0:0
#SBATCH -o GATK_haplotypecaller_%j.out
#SBATCH -e GATK_haplotypecaller_%j.err
#SBATCH --array=0-9
# Change the number of arrays according to number of parallel jobs
# ${SLURM_ARRAY_TASK_ID} will correspond to the number above

# Load modules
module load gatk
gatk --version

inDir=~/scratch/WGS_processing/2_Alignments/MarkDup/
outDir=~/scratch/WGS_processing/3_VariantCalling/GVCF/
ref=~/projects/def-sperling/houwaico/RawData/genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna

mkdir -p "$outDir"


# Generate file lists of equal size to facilitate running bwa-mem2 in parallel
ls "$inDir"*.bam > "$outDir"BAM_RG_MD.list
line_num=$(echo $(wc -l "$outDir"BAM_RG_MD.list) | awk '{ print $1 }')
line_per_array=$(("$line_num" / 10))
line_per_array_int=$(echo "($line_per_array+1.5)/1" | bc) # if the number is a float, convert to integer
split -a 1 --numeric-suffixes -l "$line_per_array_int" "$outDir"BAM_RG_MD.list "$outDir"BAM_RG_MD_
# This produces 10 equal lists of files, e.g. BAM_RG_MD_0, BAM_RG_MD_1 etc.


while read BAM; do
    name=$(basename "$BAM" | awk -F'_' '{ print $1 }')
    gatk --java-options '-Xmx6g' \
    HaplotypeCaller --native-pair-hmm-threads 16 \
    -I $BAM -O "$outDir""$name".g.vcf.gz \
    -R $ref -ERC GVCF \
    --tmp-dir ~/tmp/GATK
done < "$outDir"BAM_RG_MD_"$SLURM_ARRAY_TASK_ID"