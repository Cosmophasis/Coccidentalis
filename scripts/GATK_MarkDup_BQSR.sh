#!/bin/bash
#SBATCH --job-name=SR_MarkDup_BQSR_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH -t 12:0:0
#SBATCH -o SR_MarkDup_BQSR_%j.out
#SBATCH -e SR_MarkDup_BQSR_%j.out

module load gatk

gatk --version

for bam in ~/scratch/ShortReadAlignments/*_sortedRG.bam
do
name=$(awk 'BEGIN{FS=OFS="."}{NF--; print}' $bam)
gatk --java-options "Xmx16G" MarkDuplicates \
-I $bam -O ${name}_MD.bam -M ${name}_MD.txt \

done

for bam in ~/scratch/ShortReadAlignments/*_sortedRG_MD.bam
do
name=$(awk 'BEGIN{FS=OFS="."}{NF--; print}' $bam)
gatk BaseRecalibrator \
-I $bam -O ${name}_BQSR.bam \
--java-options "Xmx16G"
done
