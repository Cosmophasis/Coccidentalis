#!/bin/awk -f

BEGIN{
    FS = "\t"
    OFS = FS
}

#print the header info as-is
/^##/ {
    print
    next
}

#add sample named "Reference" to the list of samples
/^#CHROM/ {
    print $0"\tRef"
    next
}

#add homozygous reference allele to every locus.
{
    print $0"\t0/0:100,0:100:150:0,0,255"
}