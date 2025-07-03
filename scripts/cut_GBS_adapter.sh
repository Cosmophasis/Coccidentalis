#!/bin/bash

tmpdir=/tmp/cutadapt

module load python/3.10
virtualenv $tmpdir
source $tmpdir/bin/activate
pip install --no-index --upgrade pip
pip install --no-index cutadapt
cutadapt --version

outdir=~/scratch/LinkageCohortsTest/ProcessedReads

for file in *.fastq
do
echo "Trimming" $file
cutadapt -a ^TGCAG...GCTGAGATCGGAAGAGCGGTTCAGC \
-o ${outdir}/${file}_cut.fastq $file >> ${outdir}/cutadapt_results.txt
done
