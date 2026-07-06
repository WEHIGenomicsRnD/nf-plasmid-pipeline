#!/usr/bin python

import os
import pandas as pd
import urllib.request
import shutil


test_file='https://raw.githubusercontent.com/nf-core/test-datasets/refs/heads/modules/data/genomics/prokaryotes/bacteroides_fragilis/nanopore/fastq/test.fastq.gz'
test_path = f"{os.getcwd()}/test_data" 

def download_test():

    os.makedirs(f"{test_path}/fastq", exist_ok=True)
    result = os.system(f"wget -P test/gdj634/fastq_pass/barcode01/ {test_file}")
    os.system(f"tar -cvf {test_path}/fastq/gdj634_fastq_pass.tar test/gdj634/fastq_pass/barcode01/*.gz")

def download_urllib():

    barcode_dir = "test/gdj634/fastq_pass/barcode01"
    os.makedirs(barcode_dir, exist_ok=True)
    os.makedirs(f"{test_path}/fastq", exist_ok=True)

    # Download file using urllib
    filename = os.path.basename(test_file)
    download_dest = f"{barcode_dir}/{filename}"

    print(f"Downloading {filename}...")
    urllib.request.urlretrieve(
        test_file,
        download_dest
    )
    print(f"Downloaded to: {download_dest}")

    # Create tar archive using shutil (pure python — no os.system)
    tar_output = f"{test_path}/fastq/gdj634_fastq_pass.tar"
    
    print(f"Creating tar archive: {tar_output}")
    shutil.make_archive(
        base_name = f"{test_path}/fastq/gdj634_fastq_pass",
        format    = 'tar',
        root_dir  = ".",
        base_dir  = "test/gdj634/fastq_pass/"
    )
    print(f"Archive created: {tar_output}")

    return tar_output


def create_ssheet():
    df = pd.DataFrame({'Researcher Name': ['test'], 'Researcher Email': ['test.g@test.com'], 'Barcode':['01'], 'Sample ID': ['PEV2'], 'Size' : [2000] ,'Reference File Name': [''], 'Circular' : ['Yes'] ,'QC method' : ['Qubit']})

    df.to_excel(f"20260212_Plasmid_Batch12.xlsx", startrow=1, index=False)
    os.system(f"zip -r {test_path}/Batchtest.zip *.xlsx")
    os.system(f"rm *.xlsx")
    os.system(f"rm -rf test/")

def main():
    download_urllib()
    create_ssheet()
    

if __name__ == "__main__":
   main()
