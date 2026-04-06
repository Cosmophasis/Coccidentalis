#!/bin/bash
#SBATCH --job-name=05a_VCF_filter_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 16
#SBATCH --mem=24G
#SBATCH -t 1-0:0:0
#SBATCH -o 05a_VCF_filter_%j.out
#SBATCH -e 05a_VCF_filter_%j.out

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

mkdir -p "$outDir"

export _JAVA_OPTIONS='-Xmx20g'

# Combine VCF from all Chromosomes to one file
bcftools concat \
-f ~/tmp/vcf.list \
-Ov -o "$SLURM_TMPDIR"/all_chr.vcf \
--threads "$SLURM_CPUS_PER_TASK" -W=tbi


# GATK hard filtering
gatk VariantFiltration \
-R $ref -V "$SLURM_TMPDIR"/all_chr.vcf \
-filter "QD < 2.0" --filter-name "QD2" \
-filter "SOR > 3.0" --filter-name "SOR3" \
-filter "FS > 60.0" --filter-name "FS60" \
-filter "MQ < 40.0" --filter-name "MQ40" \
-filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
-filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \
-O "$SLURM_TMPDIR"/all_chr_gatk.vcf --tmp-dir "$SLURM_TMPDIR"


# Generate pre-bcftools filter stats (subsetting 5000 SNPs)
bcftools view --threads "$SLURM_CPUS_PER_TASK" \
-h "$SLURM_TMPDIR"/all_chr_gatk.vcf > "$SLURM_TMPDIR"/header.vcf
bcftools view --threads "$SLURM_CPUS_PER_TASK" \
-H -m2 -M2 -v snps "$SLURM_TMPDIR"/all_chr_gatk.vcf | shuf -n 5000 > "$SLURM_TMPDIR"/subset.vcf
cat "$SLURM_TMPDIR"/header.vcf "$SLURM_TMPDIR"/subset.vcf > "$SLURM_TMPDIR"/header_subset.vcf
bcftools query --threads "$SLURM_CPUS_PER_TASK" \
-i "filter='PASS'" -f '%CHROM\t%POS\t%DP\t%QUAL\t%QD\t%AF{0}\t%MQ\n' \
"$SLURM_TMPDIR"/header_subset.vcf > "$outDir"HardFiltered_stats.txt



# First round of bcftools filter
bcftools filter --threads "$SLURM_CPUS_PER_TASK" -Ou \
-S . -e 'FMT/DP<3 | FMT/GQ<20 | FMT/DP>50' "$SLURM_TMPDIR"/all_chr_gatk.vcf | \
bcftools filter --threads "$SLURM_CPUS_PER_TASK" -Ou \
-e 'AC==0 || AC==AN' --SnpGap 5 | \
bcftools view --threads "$SLURM_CPUS_PER_TASK" -Ou\
-m2 -M2 -v snps | \
bcftools +fill-tags --threads "$SLURM_CPUS_PER_TASK" \
-Ob -o "$outDir"BCGSC_PacBio_GATKbcftool1_filtered.bcf -W=tbi \
-- -t F_MISSING,MAF
# If a sample has DP<3 or DP>27 (2*AVG(INFO/DP)) convert to missing gt (./.)
# Remove variants that lack reference alleles and remove variants within 5bp of INDELS
# Only output biallelic SNPs


# Generate sample stats
bcftools stats --threads 16 \
-s - "$outDir"BCGSC_PacBio_GATKbcftool1_filtered.bcf \
> "$outDir"Filtered_sample_stats.txt