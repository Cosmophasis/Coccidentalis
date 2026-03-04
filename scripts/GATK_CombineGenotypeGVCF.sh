#!/bin/bash
#SBATCH --job-name=GATK_CombineGVCF_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 12
#SBATCH --mem=48G
#SBATCH -t 3-0:0:0
#SBATCH -o GATK_CombineGVCF_%j.out
#SBATCH -e GATK_CombineGVCF_%j.out

module load gatk

inDir=~/scratch/WGS_processing/3_VariantCalling/GVCF/
outDir=~/scratch/WGS_processing/3_VariantCalling/VCF/
ref=~/projects/def-sperling/houwaico/RawData/genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna


# Generate list of gvcf files to analyze
ls "$inDir"*g.vcf.gz > "$outDir"gvcfs.list


# Run CombineGVCFs
gatk --java-options "-Xmx4g" CombineGVCFs \
--variant "$outDir"gvcfs.list -O "$outDir"combined.g.vcf.gz \
-R "$ref" --tmp-dir "$SLURM_TMPDIR"

# Run GenotypeGVCFs
gatk --java-options "-Xmx4g" GenotypeGVCFs \
--variant "$outDir"combined.g.vcf.gz -O "$outDir"genotyped.vcf.gz -R "$ref" \
--include-non-variant-sites true \
--tmp-dir "$SLURM_TMPDIR" --create-output-variant-index 