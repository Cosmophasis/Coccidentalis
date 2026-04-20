#!/bin/bash
#SBATCH --job-name=twisst2_loop_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 8
#SBATCH --mem-per-cpu=24G
#SBATCH -t 1-0:0:0
#SBATCH -o 01_twisst2_loop_%j.out
#SBATCH -e 01_twisst2_loop_%j.err
#SBATCH --array=1-30


# python virtual env created ahead of time with sticcs and twisst2
source ~/software/twisst_env/bin/activate
module load bcftools scipy-stack/2026a


BCF=~/scratch/WGS_processing/05_Filtered_VCF/AllChr_wPacBio_GATKbcftools2.bcf
speciesSet=~/scratch/twisst2/speciesSet1/wCluster_groupname.txt
prefix=~/scratch/twisst2/speciesSet1/AllTaxa_wClusterCollapsed
Chr=$(awk -v num="$SLURM_ARRAY_TASK_ID" 'NR==num' ~/tmp/chr.list)


# Check if arguments are provided
# [[ $@ ]] || { echo "Usage: ""$0"" <groups_file> <output_prefix>"; exit 1; }


#while read Chr; do
    echo "Creating tmp vcf for Chr ""$Chr"
    bcftools view --threads "$SLURM_CPUS_PER_TASK" \
    -r $Chr -Ov -o "$SLURM_TMPDIR"/"$Chr".vcf \
    $BCF
    sticcs prep -i "$SLURM_TMPDIR"/"$Chr".vcf -o "$SLURM_TMPDIR"/"$Chr"_addDC.vcf \
    --outgroup SRR25758751
    echo "Running twisst2 sticcstack for Chr ""$Chr"
    twisst2 sticcstack -i "$SLURM_TMPDIR"/"$Chr"_addDC.vcf -o "$prefix" \
    --group_names $(cut -d" " -f2 $speciesSet | sort | uniq | tr '\n' ' ') \
    --groups_file "$speciesSet" --max_subtrees 512
#done < <(head -n -1 ~/tmp/chr.list)