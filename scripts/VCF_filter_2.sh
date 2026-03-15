#!/bin/bash
#SBATCH --job-name=bcftools_filter_2_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 16
#SBATCH --mem=32G
#SBATCH -t 1-0:0:0
#SBATCH -o bcftools_filter_2_%j.out
#SBATCH -e bcftools_filter_2_%j.out

# Load modules
module load bcftools
bcftools --version

VCF_bi=~/scratch/WGS_processing/3_VariantCalling/VCF/BCGSC_OldReads_genotyped_AllChr_filter_GATKbcftools_tags.vcf.gz
VCF_AC=~/scratch/WGS_processing/3_VariantCalling/VCF/BCGSC_OldReads_genotyped_AllChr_filter_GATKbcftools_AC.vcf.gz
VCF_MAF1=~/scratch/WGS_processing/3_VariantCalling/VCF/BCGSC_OldReads_genotyped_AllChr_filter_GATKbcftools_MAF02.vcf.gz
VCF_MAF2=~/scratch/WGS_processing/3_VariantCalling/VCF/BCGSC_OldReads_genotyped_AllChr_filter_GATKbcftools_MAF05.vcf.gz


#Steps in order
# Only keep sites that passed GATK filters
# Remove sites based on minimum alt allele count (AC) based on minimum samples
# Remove sites based on amount of missing data (F_MISSING) less than 20%

bcftools filter --threads 16 -i 'FILTER="PASS"' "$VCF_bi" | \
bcftools filter --threads 16 -e 'AC<4 || F_MISSING>0.2' \
-Oz -o "$VCF_AC" -W=tbi

# Filter by MAF instead

bcftools filter --threads 16 -i 'FILTER="PASS"' "$VCF_bi" | \
bcftools filter --threads 16 -e 'MAF<0.02 || F_MISSING>0.2' \
-Oz -o "$VCF_MAF1" -W=tbi

bcftools filter --threads 16 -i 'FILTER="PASS"' "$VCF_bi" | \
bcftools filter --threads 16 -e 'MAF<0.05 || F_MISSING>0.2' \
-Oz -o "$VCF_MAF2" -W=tbi