#!/bin/bash
#SBATCH --job-name=plink_PCA_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 4
#SBATCH --mem=8G
#SBATCH -t 00:30:00
#SBATCH -o plink_PCA_%j.out
#SBATCH -e plink_PCA_%j.err

module load plink

vcf_filter=~/scratch/genotyped_biallelic_filter.bcf
plink --vcf ${vcf_filter} \
--double-id --allow-extra-chr --set-missing-var-ids @:# \
--make-bed --pca --out LC_pca
