#!/bin/bash
#SBATCH --job-name=Concatenated_tree_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 20
#SBATCH --mem=60G
#SBATCH -t 1-0:0:0
#SBATCH -o Concatenated_tree_%j.out
#SBATCH -e Concatenated_tree_%j.out
#SBATCH --array=1-29

module load iq-tree python bcftools

ls ~/scratch/WGS_processing/05_Filtered_VCF/*l1_filtered_tagged.bcf > ~/tmp/bcf.list
VCF=$(awk -v num="$SLURM_ARRAY_TASK_ID" 'NR==num' ~/tmp/bcf.list)
#Chr="CM046102.1,CM046103.1,CM046104.1,CM046105.1,CM046106.1,CM046107.1,CM046108.1,CM046109.1,CM046110.1,CM046111.1,CM046112.1,CM046113.1,CM046114.1,CM046115.1,CM046116.1,CM046117.1,CM046118.1,CM046119.1,CM046120.1,CM046121.1,CM046122.1,CM046123.1,CM046124.1,CM046125.1,CM046126.1,CM046127.1,CM046128.1,CM046129.1,CM046130.1"
outDir=~/scratch/Phylogenomics/Concatenated/

name=$(basename "$VCF" | awk -F"_" '{ print $1"_"$2 }')

# Output a temporary file to the node local directory
bcftools view --threads "$SLURM_CPUS_PER_TASK" \
-i "FILTER='PASS'" -Ov "$VCF" | \
bcftools view --threads "$SLURM_CPUS_PER_TASK" \
-e "F_MISSING>0.2 || AC<4" -Ob -o ~/scratch/WGS_processing/05_Filtered_VCF/"$name"_GATKbcftools2_filtered_tagged.bcf


# Read directly from the node local directory
~/scripts/vcf2phylip.py -i ~/scratch/WGS_processing/05_Filtered_VCF/"$name"_GATKbcftools2_filtered_tagged.bcf \
--output-folder "$outDir" --output-prefix "$name"_wPacBio_MAC_noLD -o SRR25758751


# Generate a varsite file
iqtree2 -T "$SLURM_CPUS_PER_TASK" \
-s "$outDir""$name"_wPacBio_MAC_noLD.min4.phy --seqtype DNA -m GTR+ASC
# Actually run iqtree2 with the varsite file
iqtree2 -T "$SLURM_CPUS_PER_TASK" \
-s "$outDir""$name"_wPacBio_MAC_noLD.min4.phy.varsites.phy \
--seqtype DNA -m GTR+ASC -B 1000