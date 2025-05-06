#!/bin/bash
#SBATCH --job-name=GATK_haplotypecaller_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 8
#SBATCH --mem=16G
#SBATCH -t 5:00:00
#SBATCH -o GATK_haplotypecaller_%j.out
#SBATCH -e GATK_haplotypecaller_%j.err

# Load modules
module load gatk
gatk --version

ref=~/projects/def-sperling/houwaico/RawData/genome/CFum_1_genomic_ChrOnly.fna
for bamfile in *ChrOnly_RG.bam
do
    gatk --java-options "-Xmx16g" \
    HaplotypeCaller --native-pair-hmm-threads 8 \
    -I $bamfile -O ${bamfile}.g.vcf.gz \
    -R $ref -ERC GVCF
done