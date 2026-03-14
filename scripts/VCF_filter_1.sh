#!/bin/bash
#SBATCH --job-name=bcftools_filter_1_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 16
#SBATCH --mem=24G
#SBATCH -t 2-0:0:0
#SBATCH -o bcftools_filter_1_%j.out
#SBATCH -e bcftools_filter_1_%j.out

# Load modules
module load bcftools
bcftools --version

dir=~/scratch/WGS_processing/3_VariantCalling/VCF/
VCF=~/scratch/WGS_processing/3_VariantCalling/VCF/BCGSC_OldReads_genotyped_AllChr_filter_GATK.vcf.gz
VCF_bi=~/scratch/WGS_processing/3_VariantCalling/VCF/BCGSC_OldReads_genotyped_AllChr_filter_GATKbcftools.vcf.gz
Sample_data=~/scratch/WGS_processing/3_VariantCalling/VCF/BCGSC_OldReads_genotyped_AllChr_filter_GATKbcftools_samples.txt


#Steps in order
# If a sample has DP<3 or DP>27 (2*AVG(INFO/DP)) convert to missing gt (./.)
# Remove variants that lack reference alleles and remove variants within 5bp of INDELS
# Only output biallelic SNPs

bcftools filter --threads 16 -S . -e 'FMT/DP<3 | FMT/GQ<20 | FMT/DP>27' $VCF | \
bcftools filter --threads 16 -e 'AC==0 || AC==AN' --SnpGap 5 | \
bcftools view --threads 16 -m2 -M2 -v snps -Oz -o "$VCF_bi" -W=tbi

# Generate sample stats

bcftools stats --threads 16 \
-s - "$VCF_bi" > "$Sample_data"
