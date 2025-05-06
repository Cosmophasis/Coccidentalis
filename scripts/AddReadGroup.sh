#!/bin/bash

module load gatk
gatk --version

# Parse file title, first removing any directories in the file path, then filtering for the sample number only
# Read group ID and platform unit set as NA for now, since it is likely unnecessary for our purposes

for bamfile in *q_sorted.bam;
do
echo "Adding read group heading to $bamfile."
sample=$(echo $bamfile | awk -F/ '{print $NF}' | awk -F. '{print $1}')
gatk AddOrReplaceReadGroups -I $bamfile -O ${sample}_ChrOnly_RG.bam -PL ILLUMINA -SM $sample -LB $sample -ID NA -PU NA
done