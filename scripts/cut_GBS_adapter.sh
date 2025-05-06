#!/bin/bash

tmpdir=/tmp

module load python/3.10
virtualenv --no-download $tmpdir
source $tmpdir/env/bin/activate
pip install --no-index --upgrade pip
pip install --no-index cutadapt
cutadapt --version

outdir=~/scratch/LinkageCohortsTest/ProcessedReads

for file in *.fastq
do
echo "Trimming" $file
cutadapt -a GCTGAGATCGGAAGAGCGGTTCAGC -o ${outdir}/${file}_cut.fastq $file >> ${outdir}/cutadapt_results.txt
done
