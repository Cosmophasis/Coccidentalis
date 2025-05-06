#!/bin/bash

module load python

virtualenv MultiQC
source MultiQC/bin/activate
pip install --no-index --upgrade pip
pip install multiqc --no-index

multiqc .