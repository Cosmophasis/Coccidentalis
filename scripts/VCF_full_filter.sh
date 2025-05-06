#!/bin/bash

vcf=~/input

bcftools +prune -w 10kb -m 0.5 e 'AN<=24' $vcf -Ou | bcftools +fill-tags -Ou -- -t all | bcftools view -e 'HWE<=0.05' -Ou -o output.bcf