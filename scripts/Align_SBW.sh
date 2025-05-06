#!/bin/bash
#SBATCH --job-name=Align_SBW_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 8
#SBATCH --mem=16G
#SBATCH -t 10:00:00
#SBATCH -o Align_SBW_%j.out
#SBATCH -e Align_SBW_%j.err

module load bwa-mem2
module load samtools
module load seqkit

echo "bwa-mem2 version:"
bwa-mem2 version
echo "samtools version:"
samtools version
echo "seqkit version:"
seqkit version

# Check availability of Choristoneura fumiferana genome.

fna=~/projects/def-sperling/houwaico/RawData/genome/GCA_025370935.1_NRCan_CFum_1_genomic.fna.gz

if [-f "$fna" ]; then
    echo "The CFum_1 genome is avaliable."
else
    echo "Downloading the CFum_1 genome..."
    wget -P ~/projects/def-sperling/houwaico/RawData/genome \
    https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/025/370/935/GCA_025370935.1_NRCan_CFum_1/GCA_025370935.1_NRCan_CFum_1_genomic.fna.gz
fi

# Index Choristoneura fumiferana genome, if index found the skip this step.

index=~/projects/def-sperling/houwaico/RawData/genome/CFum_1_genomic_ChrOnly.bwt.2bit.64

if [-f "$index"]; then
    echo "CFum_1 genome (Chr only) index found"
else
    seqkit grep -r -p CM046* $fna -o CFum_1_genomic_ChrOnly.fna
    fna_Chr=~/projects/def-sperling/houwaico/RawData/genome/CFum_1_genomic_ChrOnly.fna
    cd ~/projects/def-sperling/houwaico/RawData/genome
    bwa-mem2 index -p CFum_1_genomic_ChrOnly $fna_Chr
    cd ~/scratch
fi

# Aligning filtered reads to the genome.

readDir=~/scratch/LinkageCohortsTest/ProcessedReads/
samDir=~/scratch/LinkageCohortsTest/Alignments
cd $samDir

for file in ${readDir}*cut.fastq_fastp2.fastq
do
    echo "Aligning $file to CFum indexed genome..."
    bwa-mem2 mem -t 8 -c 1 -o ${file}.sam \
    ~/projects/def-sperling/houwaico/RawData/genome/CFum_1_genomic_ChrOnly $file
    samtools view -@ 8 -q 10 -o ${file}.bam ${file}.sam
    samtools sort -o ${file}_sorted.bam ${file}.bam
done

# Moving all alignment files to the right folder.

mv ${readDir}*.sam $samDir
mv ${readDir}*.bam $samDir