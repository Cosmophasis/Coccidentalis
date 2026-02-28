#!/bin/bash
#SBATCH --job-name=GATK_haplotypecaller_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 12
#SBATCH --mem=48G
#SBATCH -t 2-0:0:0
#SBATCH -o GATK_haplotypecaller_%j.out
#SBATCH -e GATK_haplotypecaller_%j.out
#SBATCH --array=0-8
# Change the number of arrays according to
# your number of samples. Here I have (n=9)
# ${SLURM_ARRAY_TASK_ID} will correspond to the number above

# Load modules
module load gatk
gatk --version

# My absolute paths
ref=~/links/scratch/RawData/Genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna
inDir=~/links/scratch/ShortReadAlignments
outDir=~/links/scratch/VariantCalling

# Creating the array object to index
cd $inDir
bams=($(ls *_MD.bam)) # This lists all the files I'm inputting
bam=${bams[${SLURM_ARRAY_TASK_ID}]} # Index the array for individual files

echo "Calling haplotypes for "${bam[${SLURM_ARRAY_TASK_ID}]}

gatk --java-options "-Xmx48g" \
HaplotypeCaller --native-pair-hmm-threads 12 \
-I $bam -O ${outDir}/${bam}.g.vcf.gz \
-R $ref -ERC GVCF \
--do-not-run-physical-phasing true \
--pcr-indel-model NONE