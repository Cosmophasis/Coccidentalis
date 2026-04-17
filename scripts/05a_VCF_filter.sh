#!/bin/bash
#SBATCH --job-name=05a_VCF_filter_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 16
#SBATCH --mem=40G
#SBATCH -t 1-0:0:0
#SBATCH -o 05a_VCF_filter_%j.out
#SBATCH -e 05a_VCF_filter_%j.out
#SBATCH --array=1-36

# Description: This script filters the GATK output variant file by Hard Filter parameters and some bcftools filters. 
#              Stat files are produced for variants that pass GATK hard filters and then for samples that pass both filters

# Load modules
module load bcftools gatk
bcftools --version


# Set  variables
inDir=~/scratch/WGS_processing/04_Genotyped/
outDir=~/scratch/WGS_processing/05_Filtered_VCF/
ref=~/projects/def-sperling/houwaico/RawData/genome/GCF_025370935.1_NRCan_CFum_1_genomic.fna
ls "$inDir"*.vcf.gz | grep -v 'NC_037395.1' > ~/tmp/vcf.list
vcfList=~/tmp/vcf.list

mkdir -p "$outDir"

export _JAVA_OPTIONS='-Xmx38g'

# Set chromosome to facilitate array job
VCF=$(awk -v num="$SLURM_ARRAY_TASK_ID" 'NR==num' "$vcfList")
name=$(basename "$VCF" .vcf.gz)


# Combine VCF from all Chromosomes to one file
#bcftools concat \
#-f ~/tmp/vcf.list \
#-Ov -o "$SLURM_TMPDIR"/all_chr.vcf \
#--threads "$SLURM_CPUS_PER_TASK"


# GATK hard filtering
gatk VariantFiltration \
-R $ref -V $VCF \
-filter "QD < 2.0" --filter-name "QD2" \
-filter "SOR > 3.0" --filter-name "SOR3" \
-filter "FS > 60.0" --filter-name "FS60" \
-filter "MQ < 40.0" --filter-name "MQ40" \
-filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
-filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \
-O "$outDir""$name"_gatk.vcf.gz \
--tmp-dir "$SLURM_TMPDIR" --QUIET true


# First round of bcftools filter for PacBio reads
bcftools view --threads "$SLURM_CPUS_PER_TASK" \
-s SRR25758751,SRR35559941 -Ou "$outDir""$name"_gatk.vcf.gz |
bcftools filter --threads "$SLURM_CPUS_PER_TASK" -Ob -W=tbi \
-S . -e 'FMT/DP<3 | FMT/GQ<20 | FMT/DP>200' -o "$SLURM_TMPDIR"/"$name"_PacBioOnly_GATK_setMissing.bcf
# If a sample has DP<3 or DP>200 (set based on distribution) convert to missing gt (./.)

# First round of bcftools filter for non-PacBio reads
bcftools view --threads "$SLURM_CPUS_PER_TASK" \
-s ^SRR25758751,SRR35559941 -Ou $VCF |
bcftools filter --threads "$SLURM_CPUS_PER_TASK" -Ob -W=tbi \
-S . -e 'FMT/DP<3 | FMT/GQ<20 | FMT/DP>50' -o "$SLURM_TMPDIR"/"$name"_nonPacBio_GATK_setMissing.bcf
# If a sample has DP<3 or DP>50 (set based on distribution) convert to missing gt (./.)

# Merge the PacBio and non-PacBio BCFs
ls "$SLURM_TMPDIR"/*GATK_setMissing.bcf > "$SLURM_TMPDIR"/merge_bcf.list
bcftools merge --threads "$SLURM_CPUS_PER_TASK" -W=tbi \
-l "$SLURM_TMPDIR"/merge_bcf.list \
-Ob -o "$SLURM_TMPDIR"/"$name"_GATK_setMissing.bcf

bcftools filter --threads "$SLURM_CPUS_PER_TASK" -Ou \
-e 'AC==0 || AC==AN' --SnpGap 5 "$SLURM_TMPDIR"/"$name"_GATK_setMissing.bcf | \
bcftools view --threads "$SLURM_CPUS_PER_TASK" -Ou -m2 -M2 -v snps | \
bcftools +fill-tags --threads "$SLURM_CPUS_PER_TASK" \
-Ob -o "$outDir""$name"_GATKbcftools1.bcf -W=tbi \
-- -t F_MISSING,MAF
# Remove variants that lack reference alleles and remove variants within 5bp of INDELS
# Only output biallelic SNPs


# Generate pre-bcftools filter stats (subsetting 5000 SNPs)
#bcftools view --threads "$SLURM_CPUS_PER_TASK" \
#-h "$SLURM_TMPDIR"/all_chr_gatk.vcf > "$SLURM_TMPDIR"/header.vcf
#bcftools view --threads "$SLURM_CPUS_PER_TASK" \
#-H -m2 -M2 -v snps "$SLURM_TMPDIR"/all_chr_gatk.vcf | shuf -n 5000 > "$SLURM_TMPDIR"/subset.vcf
#cat "$SLURM_TMPDIR"/header.vcf "$SLURM_TMPDIR"/subset.vcf > "$SLURM_TMPDIR"/header_subset.vcf
#bcftools query \
#-i "filter='PASS'" -f '%CHROM\t%POS\t%DP\t%QUAL\t%QD\t%AF{0}\t%MQ\n' \
#"$SLURM_TMPDIR"/header_subset.vcf > "$outDir"HardFiltered_stats.txt


# Generate sample stats
#bcftools stats --threads 16 \
#-s - "$outDir"BCGSC_PacBio_GATKbcftool1_filtered.bcf \
#> "$outDir"Filtered_sample_stats.txt