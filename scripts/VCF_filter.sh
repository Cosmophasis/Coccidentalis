#!/bin/bash
#SBATCH --job-name=VCF_filter_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 4
#SBATCH --mem=12G
#SBATCH -t 00:30:00
#SBATCH -o VCF_filter_%j.out
#SBATCH -e VCF_filter_%j.err

# Load modules
module load bcftools
bcftools --version

vcf=~/scratch/genotyped.vcf.gz

# Filter samples based on missing genotype calls
# 1. Preliminary filter
bcftools view --threads 4 -m2 -M2 -v snps \
-O u -o genotyped_biallelic.bcf $vcf
# 2. Query .vcf for a table of genotype calls per sample
#bcftools query -HH -f '[%GT\t]' genotyped.vcf.gz
# 3. Some table stuff to calculate total number of 

vcf_bi=~/scratch/genotyped_biallelic.bcf

bcftools view --threads 4 \
-i 'AN>20 & MAF>0.03 & MIN(FMT/DP)>5 & MIN(FMT/GQ)>30' \
-O u -o genotyped_biallelic_filter.bcf ${vcf_bi}
