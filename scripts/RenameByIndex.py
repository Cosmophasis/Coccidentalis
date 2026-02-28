import os
import pandas as pd

indexes = pd.read_csv("/home/houwaico/scratch/WGS_processing/Sample_index.tsv", sep='\t')

os.chdir("/home/houwaico/projects/def-sperling/SBW_data/2026_BC_GSC")

for sample in indexes.index:
    if not os.path.exists(indexes.loc[sample, 'index_file_1']):
        print("Skipping")
        continue
    os.rename(indexes.loc[sample, 'index_file_1'], indexes.loc[sample, 'sample_file_1'])
    os.rename(indexes.loc[sample, 'index_file_2'], indexes.loc[sample, 'sample_file_2'])
