#!/bin/bash

module load admixture

bed=~/scratch/LCFullFilter_pca.bed
prefix=`echo $bed | awk -F / '{print $NF}' | awk -F . '{print $1}'`
awk '{$1="0";print $0}' ${prefix}.bim > ${prefix}.bim.tmp
mv ${prefix}.bim.tmp ${prefix}.bim

for i in {1..10}
do
 admixture --cv $bed $i > admix${i}.out
done

awk '/CV/ {print $3,$4}' admix* | sed -e 's/(//;s/)//;s/://;s/K=//' > ${prefix}.cv.error