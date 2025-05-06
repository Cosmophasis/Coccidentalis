#!/bin/bash
#SBATCH --job-name=GATK_CombineGVCF_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 8
#SBATCH --mem=64G
#SBATCH -t 1:00:00
#SBATCH -o GATK_CombineGVCF_%j.out
#SBATCH -e GATK_CombineGVCF_%j.err

# Load modules
module load gatk
gatk --version

ref=~/projects/def-sperling/houwaico/RawData/genome/CFum_1_genomic_ChrOnly.fna

find ./ -type f -name "*.g.vcf.gz" > gvcfs.list

gatk --java-options "-Xmx32g" CombineGVCFs \
--variant gvcfs.list -O combined.g.vcf.gz \
-R $ref