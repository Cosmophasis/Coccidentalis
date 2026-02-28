#!/bin/bash
#SBATCH --job-name=GATK_HardFilter_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH -t 6:0:0
#SBATCH -o GATK_HardFilter_%j.out
#SBATCH -e GATK_HardFilter_%j.out

module load gatk
gatk --version

ref=~/links/scratch/RawData/Genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna
inDir=~/links/scratch/VariantCalling

gatk --java-options "-Xmx32g" VariantFiltration \
-R $ref -V ${inDir}/SNP.vcf \
-filter "QD < 2.0" --filter-name "QD2" \
-filter "QUAL < 30.0" --filter-name "QUAL30" \
-filter "SOR > 3.0" --filter-name "SOR3" \
-filter "FS > 60.0" --filter-name "FS60" \
-filter "MQ < 40.0" --filter-name "MQ40" \
-filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
-filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \
-O ${inDir}/SNP_hard.vcf
