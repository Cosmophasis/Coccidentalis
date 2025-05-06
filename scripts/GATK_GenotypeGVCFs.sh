#!/bin/bash
#SBATCH --job-name=GATK_GenotypeGVCFs_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 8
#SBATCH --mem=64G
#SBATCH -t 24:00:00
#SBATCH -o GATK_GenotypeGVCFs_%j.out
#SBATCH -e GATK_GenotypeGVCFs_%j.err

# Load modules
module load gatk
gatk --version

ref=~/projects/def-sperling/houwaico/RawData/genome/CFum_1_genomic_ChrOnly.fna

gatk --java-options "-Xmx64g" GenotypeGVCFs \
--variant combined.g.vcf.gz -O genotyped.vcf.gz \
-R $ref