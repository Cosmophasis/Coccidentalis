#!/bin/bash
#SBATCH --job-name=03_04_GATK_GenomicsDB_Genotype_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 20
#SBATCH --mem=80G
#SBATCH -t 2-0:0:0
#SBATCH -o 03_04_GATK_GenomicsDB_Genotype_%j.out
#SBATCH -e 03_04_GATK_GenomicsDB_Genotype_%j.out
#SBATCH --array=1-32


# Set variables
DBDir=~/scratch/WGS_processing/03_GenomicsDB/
VCFDir=~/scratch/WGS_proessing/04_Genotyped/
sampleMap=~/tmp/gvcf_map.list
chrList=~/tmp/chr.list
ref=~/projects/def-sperling/houwaico/RawData/genome/GCF_025370935.1_NRCan_CFum_1_genomic.fna

mkdir -p "$DBDir"
mkdir -p "$VCFDir"

export _JAVA_OPTIONS='-Xmx75g'


# Set chromosome to facilitate array job
Chr=$(awk -v num="$SLURM_ARRAY_TASK_ID" 'NR==num' "$chrList")


# Run GenomicsDBImport
gatk GenomicsDBImport \
--genomicsdb-workspace-path "$DBDir""$Chr" \
--sample-name-map "$sampleMap" -L "$Chr" \
--batch-size 50 --genomicsdb-shared-posixfs-optimizations true \
--tmp-dir "$SLURM_TMPDIR" --reader-threads "$SLURM_CPUS_PER_TASK"


# Run GenotypeGVCFs
gatk GenotypeGVCFs \
-V gendb://"$DBDir""$Chr" -O "$VCFDir""$Chr".vcf.gz -R "$ref" \
--include-non-variant-sites true \
--tmp-dir "$SLURM_TMPDIR" --create-output-variant-index 