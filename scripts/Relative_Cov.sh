#!/bin/bash

module load samtools

# Start clean file
echo -e "sample\tMeanDP_Z\tMeanDP_Auto\tRatio_ZtoAuto" > Relative_Cov_Output.txt
AutoNum=29

for bam in ./*bam; do
    sample=$(basename $bam .bam)
    echo "Processing "$sample
    samtools coverage $bam > Relative_Cov_tmp.txt
    Z=$(awk 'NR==2 { print $7 }' Relative_Cov_tmp.txt)
    AutoSum=$(awk 'NR==3, NR==31 {sum+=$7} END {print sum}' Relative_Cov_tmp.txt)
    Auto=$(echo "scale=3; $AutoSum / $AutoNum" | bc)
    Ratio=$(echo "scale=3; $Z / $Auto" | bc)
    echo -e "$sample\t$Z\t$Auto\t$Ratio" >> Relative_Cov_Output.txt
done

rm Relative_Cov_tmp.txt