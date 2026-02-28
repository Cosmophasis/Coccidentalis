#!/bin/bash
#SBATCH --job-name=GATK_GenotypeGVCFs_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 16
#SBATCH --mem=64G
#SBATCH -t 3-0:0:0
#SBATCH -o GATK_GenotypeGVCFs_%j.out
#SBATCH -e GATK_GenotypeGVCFs_%j.out

# Load modules
module load gatk
gatk --version

ref=~/links/scratch/RawData/Genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna
inDir=~/links/scratch/VariantCalling

gatk --java-options "-Xmx64g" GenotypeGVCFs \
--variant ${inDir}/combined.g.vcf.gz -O ${inDir}/genotyped.vcf.gz \
-R $ref