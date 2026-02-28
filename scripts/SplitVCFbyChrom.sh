#!/bin/bash

module load bcftools

vcf=~/links/scratch/VariantCalling/SNP_HardFilter_NoMissing_wRef_LDprune2.vcf.gz
vcf=${vcf%.*}
vcf=${vcf%.*}
#Run twice to remove both the file extension and the compression

#List all the chromosomes/contigs listed in the vcf file
#grep "CM" because that's how the chromosome level contigs start
contigs=($(bcftools view -h ${vcf}.vcf.gz | \
awk 'BEGIN{FS="=";OFS=FS}/^##contig/{print $3}' | \
awk 'BEGIN{FS=",";OFS=FS}{print $1}' | grep "CM"))

#For some reason bcftools view only works for compressed vcfs
for chr in "${contigs[@]}"
do
echo "Creating subset .vcf file for chromosome "$chr
bcftools view "$vcf".vcf.gz --regions $chr -O z -o "$vcf"_"$chr".vcf.gz
done