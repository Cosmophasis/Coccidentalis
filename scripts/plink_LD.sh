#!/bin/bash

vcf=~/

plink --vcf $vcf\
--double-id --allow-extra-chr --set-missing-var-ids @:# --make-bed