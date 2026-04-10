import argparse

# Add arguments
parser = argparse.ArgumentParser(
                    prog='DropGappyTaxa',
                    description="Remove taxa with high proportion of missing data from phylip file.",
                    epilog='Your partially missing data is now completely missing :)')
parser.add_argument('-i', '--infile')
parser.add_argument('-o', '--outfile')
parser.add_argument('-m', '--percmissing'
                    , nargs='?' , type=float, default=0.8)
args = parser.parse_args()

print("Processing " + args.infile)


# Read phylip file
with open(args.infile, 'r') as file:
    lines = file.readlines()
# Create data matrix of missing data per taxon
    # Iterate over the rows of taxa in each phylip
    # Calculate PercMissing for each taxa, if more than threshold then append to list of taxa to drop

header = lines[0].split()

output = []
for line in lines[1:]: 
    # Split line into taxon (0) and sequence (1)
    fields = line.split()
    PercMissing = fields[1].count("-")/len(fields[1])
    # Drop list of taxa with high missingness
    if PercMissing < args.percmissing:
        output.append(line)


# Update header of the phylip file
new_header = str(len(output)) + " " + header[1] + '\n'
output.insert(0, new_header)


# Write phylip file
with open(args.outfile, 'w') as file:
    for line in output:
        file.writelines({line})


print("Created " + args.outfile)
