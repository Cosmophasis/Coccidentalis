#!/bin/bash

module load python
module load gcc arrow/19.0.1

dir=~/tmp/MultiQC

virtualenv $dir
source ${dir}/bin/activate
pip install --no-index --upgrade pip
pip install multiqc

multiqc .