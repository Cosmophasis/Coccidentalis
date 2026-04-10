#!/bin/bash
#SBATCH --job-name=TopoWindows_loop_%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=colinchiu62@gmail.com
#SBATCH --ntasks=1
#SBATCH -c 20
#SBATCH --mem=80G
#SBATCH -t 2-0:0:0
#SBATCH -o TopoWindows_loop_%j.out
#SBATCH -e TopoWindows_loop_%j.out
#SBATCH --array=1-30
    # Change the number of arrays according to number of parallel jobs
    # ${SLURM_ARRAY_TASK_ID} will correspond to the number above


module load r bcftools iq-tree python scipy-stack/2026a
export R_LIBS=~/.local/R/$EBVERSIONR/


ls ~/scratch/WGS_processing/05_Filtered_VCF/*_GATKbcftools2_filtered_tagged.bcf > ~/tmp/bcf.list
BCFlist=~/tmp/bcf.list
BCF=$(awk -v num="$SLURM_ARRAY_TASK_ID" 'NR==num' "$BCFlist")
name=$(basename $BCF | awk -F'_' '{ print $1,$2 }')


window="c" # c for region, s for no. of SNPs
size="100000" # if c in $window, put in number of bp
if [ $window == "c" ]; then
    size_kb=$(("$size"/1000))
    outDir=~/scratch/Phylogenomics/"$size_kb"kb/
#    mkdir -p "$outDir"{fasta,tree}
elif [ $window == "s" ]; then
    outDir=~/scratch/Phylogenomics/"$size"SNPs/
#    mkdir -p "$outDir"{fasta,tree}
else
    echo "Unrecognized window type, choose either 'c' for bp or 's' for SNPs"
fi

mkdir -p "$SLURM_TMPDIR"/{fasta,tree}

# Split chr by array task id
#chr_num_1=$((2*"$SLURM_ARRAY_TASK_ID"-1))
#chr_num_2=$((2*"$SLURM_ARRAY_TASK_ID"))
#declare -a chr_array=($(awk -v num="$chr_num_1" 'NR == num' $Chrlist) $(awk -v num="$chr_num_2" 'NR == num' $Chrlist))


# Run TopoWindows R script on the designated chromosomes
#for Chr in "${chr_array[@]}"; do
    # Generate temp. .vcf file per chr
    bcftools view --threads "$SLURM_CPUS_PER_TASK" -Ov -o "$SLURM_TMPDIR"/"$name".vcf "$BCF"
    # Generate fasta per chr
    Rscript ~/software/TopoWindows/Topo_windows_v04_cl_wrapper.R \
    --vcf "$SLURM_TMPDIR"/"$name".vcf \
    --window_type "$window" --size "$size" --incr 0 \
    --phased F --prefix "$SLURM_TMPDIR"/fasta/"$name" --ali T --tree N --force T
    for fasta in "$SLURM_TMPDIR"/fasta/"$name"_sequences/*.fasta; do
        fa_name=$(basename "$fasta")
        # Run iqtree (first generate varsite then run iqtree on that)
        iqtree2 -s "$fasta" --prefix "$SLURM_TMPDIR"/tree/"$fa_name" \
        -T "$SLURM_CPUS_PER_TASK" -st DNA -m GTR+ASC
        # Add step to remove samples without data
        python ~/scripts/DropGappyTaxa_phylip.py \
        -i "$SLURM_TMPDIR"/tree/"$fa_name".varsites.phy -o "$SLURM_TMPDIR"/tree/"$fa_name".varsites.nMiss.phy -m 0.8  
        iqtree2 -s "$SLURM_TMPDIR"/tree/"$fa_name".varsites.nMiss.phy \
        -T "$SLURM_CPUS_PER_TASK" -st DNA -m GTR+ASC --abayes
    done
#done

mv "$SLURM_TMPDIR"/fasta "$outDir"
mv "$SLURM_TMPDIR"/tree "$outDir"