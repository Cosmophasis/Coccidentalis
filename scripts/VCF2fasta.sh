#!/bin/bash

module load bcftools

ref_fai=~/links/scratch/RawData/Genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna.fai
vcf=~/links/scratch/VariantCalling/SNP_HardFilter_NoMissing_wRef.bcf
mapfiles -t samples < <(cat ~/links/scratch/Phylogeny/fasta/samples.txt)

outDir=~/links/scratch/Phylogeny/fasta

for sample in "${samples[@]}"
do
bcftools consensus -f $ref -s $sample -o ${outDir}/${sample}.fa $vcf
done