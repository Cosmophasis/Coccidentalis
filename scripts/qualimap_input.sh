#!/bin/bash

module load qualimap

for bamfile in $1
do
qualimap bamqc -bam $bamfile -c \
-outfile $bamfile -outformat PDF
done