#!/bin/bash
#SBATCH --job-name=GATK_BQSR_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 8
#SBATCH --mem-per-cpu=40G
#SBATCH -t 2-0:0:0
#SBATCH -o GATK_BQSR_%j.out
#SBATCH -e GATK_BQSR_%j.err
#SBATCH --array=0-21
    # Change the number of arrays according to number of parallel jobs
    # ${SLURM_ARRAY_TASK_ID} will correspond to the number above

module load gatk r gcc
export _JAVA_OPTIONS="-Xmx32g"

mkdir -p ~/.local/R/$EBVERSIONR/
export R_LIBS=~/.local/R/$EBVERSIONR/

bamDir=~/scratch/WGS_processing/2_Alignments/MarkDup/
bamDir1=~/projects/def-sperling/houwaico/Choristoneura_introgression/ShortReadAlignments/
vcfDir=~/scratch/WGS_processing/3_VariantCalling/VCF/
outDir=~/scratch/WGS_processing/BQSR/
ref=~/projects/def-sperling/houwaico/RawData/genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna

mkdir -p "$outDir"
mkdir -p "$outDir"Recalibrated_BAM
mkdir -p "$outDir"Recalibration_table
mkdir -p "$outDir"Covariate_analysis
mkdir -p "$outDir"logs


# Generate file lists of equal size to facilitate running jobs in parallel
ls "$bamDir"*.bam > "$outDir"BAM.list
ls "$bamDir1"*_MD.bam >> "$outDir"BAM.list

if [ ! -f "$outDir"BAM_0 ]; then
    line_num=$(wc -l "$outDir"BAM.list | awk '{ print $1 }')
    line_per_array=$(("$line_num" / 20))
    line_per_array_int=$(echo "($line_per_array+1.5)/1" | bc) # if the number is a float, convert to integer
    split -a 1 --numeric-suffixes -l "$line_per_array_int" "$outDir"BAM.list "$outDir"BAM_
fi
# This produces 10 equal lists of files, e.g. BAM_RG_MD_0, BAM_RG_MD_1 etc.

regex="^s_[0-9].+_fastp\.fastq"

while read bam; do
    if [[ $(basename "$bam") =~ $regex ]]; then
        name=$(basename "$bam" .bam | awk -F'_' '{ print $1$2$3 }')
    else
        name=$(basename "$bam" .bam | awk -F'_' '{ print $1 }')
    fi
    gatk BaseRecalibrator \
    -I $bam -R $ref \
    --known-sites "$vcfDir"BCGSC_OldReads_genotyped_AllChr_SNP_filter_GATK.vcf.gz \
    --known-sites "$vcfDir"BCGSC_OldReads_genotyped_AllChr_INDEL_filter_GATK.vcf.gz \
    -O "$outDir"Recalibration_table/"$name"_recal1.table \
    --tmp-dir "$SLURM_TMPDIR" &> "$outDir"logs/"$name"_BaseRecalibrator1.out
    gatk ApplyBQSR \
    -I $bam -R $ref \
    --bqsr-recal-file "$outDir"Recalibration_table/"$name"_recal1.table \
    -O "$outDir"Recalibrated_BAM/"$name"_BQSR1.bam \
    --tmp-dir "$SLURM_TMPDIR" &> "$outDir"logs/"$name"_ApplyBQSR1.out
    gatk AnalyzeCovariates \
    -bqsr "$outDir"Recalibration_table/"$name"_recal1.table \
    -plots "$outDir"Covariate_analysis/"$name"_recal1.pdf &> "$outDir"logs/"$name"_AnalyzeCovariates1.out
    gatk BaseRecalibrator \
    -I "$outDir"Recalibrated_BAM/"$name"_BQSR1.bam -R $ref \
    --known-sites "$vcfDir"BCGSC_OldReads_genotyped_AllChr_SNP_filter_GATK.vcf.gz \
    --known-sites "$vcfDir"BCGSC_OldReads_genotyped_AllChr_INDEL_filter_GATK.vcf.gz \
    -O "$outDir"Recalibration_table/"$name"_recal2.table \
    --tmp-dir "$SLURM_TMPDIR" &> "$outDir"logs/"$name"_BaseRecalibrator2.out
    gatk ApplyBQSR \
    -I "$outDir"Recalibrated_BAM/"$name"_BQSR1.bam -R $ref \
    --bqsr-recal-file "$outDir"Recalibration_table/"$name"_recal2.table \
    -O "$outDir"Recalibrated_BAM/"$name"_BQSR2.bam \
    --tmp-dir "$SLURM_TMPDIR" &> "$outDir"logs/"$name"_ApplyBQSR2.out
    gatk AnalyzeCovariates \
    -before "$outDir"Recalibration_table/"$name"_recal1.table \
    -after "$outDir"Recalibration_table/"$name"_recal2.table \
    -plots "$outDir"Covariate_analysis/"$name"_recal2.pdf &> "$outDir"logs/"$name"_AnalyzeCovariates2.out
done < "$outDir"BAM_"$SLURM_ARRAY_TASK_ID"