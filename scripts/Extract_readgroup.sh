#!/bin/bash

header=$(zcat $1 | head -n 1)
id=$(echo $header | head -n 1 | cut -f 1-4 -d":" | sed 's/@//' | sed 's/:/_/g')
sm=$(echo $header | head -n 1 | grep -Eo "[ATGCN]+$")
echo "Read Group @RG\tID:$id\tSM:$id"_"$sm\tLB:$id"_"$sm\tPL:ILLUMINA"

#bwa mem \
#-M \
#-t 8 \
#-v 3 \
#-R $(echo "@RG\tID:$id\tSM:$id"_"$sm\tLB:$id"_"$sm\tPL:ILLUMINA") \
#"$path_bwaindex_genome" \
#$1 $2 | samblaster -M | samtools fixmate - - | samtools sort -O bam -o "mapped-bwa.bam"