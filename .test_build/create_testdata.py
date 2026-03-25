#!/usr/bin python

import os
import pandas as pd

test_file='https://raw.githubusercontent.com/nf-core/test-datasets/refs/heads/modules/data/genomics/prokaryotes/bacteroides_fragilis/nanopore/fastq/test.fastq.gz'
test_path = f"{os.getcwd()}/test_data" 

def download_test():

    os.makedirs(f"{test_path}/fastq", exist_ok=True)
    result = os.system(f"wget -P test/gdj634/fastq_pass/barcode01/ {test_file}")
    os.system(f"tar -cvf {test_path}/fastq/gdj634_fastq_pass.tar test/gdj634/fastq_pass/barcode01/*.gz")

def create_ssheet():
    df = pd.DataFrame({'Researcher Name': ['test'], 'Researcher Email': ['test.g@test.com'], 'Barcode':['01'], 'Sample ID': ['PEV2'], 'Size' : [2000] ,'Reference File Name': [''], 'Circular' : ['Yes']})

    df.to_excel(f"20260212_Plasmid_Batch12.xlsx", startrow=1, index=False)
    os.system(f"zip -r {test_path}/Batchtest.zip *.xlsx")
    os.system(f"rm *.xlsx")
    os.system(f"rm -rf test/")

def main():
    download_test()
    create_ssheet()
    

if __name__ == "__main__":
   main()
