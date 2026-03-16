#!/bin/bash
#SBATCH --job-name=Concatenated_tree_NoSex_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 20
#SBATCH --mem=60G
#SBATCH -t 1-0:0:0
#SBATCH -o Concatenated_tree_NoSex_%j.out
#SBATCH -e Concatenated_tree_NoSex_%j.out

module load iq-tree
module load python
module load bcftools

VCF=~/scratch/WGS_processing/3_VariantCalling/VCF/BCGSC_OldReads_genotyped_AllChr_filter_GATKbcftools_AC.vcf.gz
Chr="CM046102.1,CM046103.1,CM046104.1,CM046105.1,CM046106.1,CM046107.1,CM046108.1,CM046109.1,CM046110.1,CM046111.1,CM046112.1,CM046113.1,CM046114.1,CM046115.1,CM046116.1,CM046117.1,CM046118.1,CM046119.1,CM046120.1,CM046121.1,CM046122.1,CM046123.1,CM046124.1,CM046125.1,CM046126.1,CM046127.1,CM046128.1,CM046129.1,CM046130.1"
outDir=~/scratch/Phylogenomics/Concatenated/


# Output a temporary file to the node local directory
bcftools view --threads 20 -Ov -o ~/tmp/tmp.vcf "$VCF" -r "$Chr"
mv ~/tmp/tmp.vcf "$SLURM_TMPDIR"
# Read directly from the node local directory
~/scripts/vcf2phylip.py -i "$SLURM_TMPDIR"/tmp.vcf --output-folder "$outDir" --output-prefix NoSexChr_AC_noLD


# Generate a varsite file
iqtree2 -T 20 -p "$outDir"NoSexChr_AC_noLD.min4.phy --seqtype DNA -m GTR+ASC
# Actually run iqtree2 with the varsite file
iqtree2 -T 20 -p "$outDir"NoSexChr_AC_noLD.min4.phy.varsites.phy \
--seqtype DNA -m GTR+ASC -B 1000