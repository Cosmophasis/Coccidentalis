#!/bin/bash
#SBATCH --job-name=GATK_CombineGVCF_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 12
#SBATCH --mem=48G
#SBATCH -t 12:00:00
#SBATCH -o GATK_CombineGVCF_%j.out
#SBATCH -e GATK_CombineGVCF_%j.out

# Load modules
module load gatk
gatk --version

ref=~/links/scratch/RawData/Genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna
inDir=~/links/scratch/VariantCalling

#find ./ -type f -name "*.g.vcf.gz" > gvcfs.list

gatk --java-options "-Xmx48g" CombineGVCFs \
--variant ${inDir}/gvcfs.list -O ${inDir}/combined.g.vcf.gz \
-R $ref