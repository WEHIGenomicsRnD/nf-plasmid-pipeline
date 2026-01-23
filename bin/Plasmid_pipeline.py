#!/usr/bin/env python

import os
import argparse
import logging
import pandas as pd
import numpy as np
import zipfile
import re

logging.basicConfig(format='%(asctime)s %(message)s', datefmt='%d/%m/%Y %I:%M:%S %p')

parser = argparse.ArgumentParser()
#parser.add_argument('-f','--file', help='Sample sheet file')
parser.add_argument('-o','--outdir', help='Output directory')
parser.add_argument('-i','--inpdir', help='Input directory')

args = parser.parse_args()
#inp_sheet=args.file
outdir=args.outdir
inpdir=args.inpdir
default_size = 7000

#if not inp_sheet.endswith("csv") or inp_sheet not in [".xlsx",".xls"]:
#if not re.search(r"\.xls",inp_sheet):
#    logging.warn(f"Please provide Excel or Csv file - {inp_sheet}")
#    raise SystemExit(1)
if not inpdir:

    infile="Yes"
logging.info(f"Input Dir : {inpdir}")

if not outdir:
    outdir = os.getcwd()
logging.info(f"Output Dir : {outdir}")

results={"error":[]}


## Process the input sample sheet and create researcher wise csv files ###
def process_samplesheet(inp_sheet,ref_folder):
    date=inp_sheet.strip().split(".")[0].split("_")[0]  
    if inp_sheet.endswith('.csv'):
        ss = pd.read_csv(inp_sheet, skiprows=0)
    elif re.search(r"\.xlsx",inp_sheet):
        ss = pd.read_excel(ref_folder+"/"+inp_sheet, skiprows=1)

    ss=ss.dropna(subset=['Researcher Name'])
    required_cols = ['Researcher Name', 'Barcode', 'Sample ID', 'Size', 'Reference File Name']
    missing_cols = [col for col in required_cols if col not in ss.columns]         ## Checking for missing column ##

    if missing_cols:
       logging.warning(f"The following required columns are missing: {missing_cols}")
    else:
       logging.warning("All required columns are present. Processing the DataFrame...")
    assert all([col in ss.columns for col in required_cols])
    
    print(ss)
    write_result_template(ss,inp_sheet)    ## Writing result template file ###

#    ss['Researcher'] = ss['Researcher Name'].map(lambda x: x.split(' ')[0].extract(r'([A-Za-z]{2})'))+ss['Researcher Name'].map(lambda x: x.split(' ')[-1])    # get last names
#    ss['Researcher'] = ss['Researcher Name'].str.split().apply(lambda x: x[-1] + x[0][:2])
#    researchers = np.unique(ss.Researcher)
    ss['Researcher'] = ss['Researcher Name'].map(lambda x: x.split(' ')[-1])
    temp_arr= ss[['Researcher','Researcher Email']]
    df_unique = temp_arr.drop_duplicates(subset=["Researcher"])
    print(df_unique)

    ss['Size'] = ss['Size'].map(lambda x: re.sub('\s*bp', '', re.sub('\s*kb', '000', str(x))))      # convert all sizes to integers
    ss['Size'] = ss['Size'].map(lambda x: re.sub('unknown', '7000', str(x), flags=re.IGNORECASE))
    ss['Size'] = ss['Size'].map(lambda x: re.sub('NaN', '7000', str(x), flags=re.IGNORECASE))
    ss['Size'] = ss['Size'].map(lambda x: int(float(x.strip().strip('~'))))

    ss['Sample ID'] = [re.sub(r'^([0-9]+)', r'S\1', str(sample)) for sample in ss['Sample ID'].values]  # add S to each sample ID that starts with a number (the pipeline doesn't like that)   # remove any spaces or brackets
    ss['Sample ID'] = [re.sub(r'\.(?=.*\.)', '', re.sub(r'[\s+\)\(\]\[\/\']+', '', str(sample))) for sample in ss['Sample ID'].values]


    ss['Barcode'] = ss.Barcode.map(lambda x: 'barcode' + str(int(x)).zfill(2))    # make barcodes two digits and add barcode` prefix

    ss['Reference File Name'] = ss['Reference File Name'].fillna('')    # Replace NaN with empty strings
    ss['Reference File Name'] = [                         #
         '' if not str(reference).strip() else ref_folder + "/" + re.sub(r'\.(?=.*\.)', '', re.sub(r'[\s+\)\(\]\[\/\']+', '', str(reference)))      # append path at the front and remove any spaces or brackets of reference
           for reference in ss['Reference File Name'].values]

    for refer in ss['Reference File Name'].values:
        if refer != '' and not os.path.exists(refer):
           results['error'].append(f"Reference file - {refer} doesnot exists! Please check the filename")

   # print(ss.loc[ss.Researcher == "Ozaydin"])
    new_row_names = {'Barcode': 'barcode', 'Sample ID': 'alias', 'Size': 'approx_size', 'Reference File Name': 'full_reference'}           # rename rows
    ss = ss.rename(columns=new_row_names)

    for researcher in df_unique['Researcher'].values:
       uid=df_unique.loc[df_unique['Researcher'] == researcher, 'Researcher Email'].iloc[0].split('@')[0]
       outfile = f'{date}_{uid}.csv'

       if (ss.loc[ss.Researcher == researcher, 'full_reference'] == '').all():
           write_sheet(ss.loc[(ss.Researcher == researcher) & (ss.full_reference == ''), ['barcode', 'alias', 'approx_size']],researcher,outfile)
       else:
           if len(ss.loc[(ss.Researcher == researcher) & (ss.full_reference != '')]):
               write_sheet(ss.loc[(ss.Researcher == researcher) & (ss.full_reference != ''), ['barcode', 'alias', 'approx_size','full_reference']],researcher,outfile)
           if len(ss.loc[(ss.Researcher == researcher) & (ss.full_reference == '')]):
               outfile = f'{date}_{researcher}_withoutref.csv'
               write_sheet(ss.loc[(ss.Researcher == researcher) & (ss.full_reference == ''), ['barcode', 'alias', 'approx_size']],researcher,outfile)

    if int(len(set(results['error']))) >=1:
        line="\n".join(set(results['error']))
        print(f"Printing Error")
        print(f"{line}")
    else:
        script_path=os.getcwd()
        cmd=f"sh {script_path}/Plasmid_workflow.sh {outdir}"
        print(f"Cmd - {cmd}")
#        os.system(cmd)


def write_result_template(ss,inp_sheet):
    filename=os.path.basename(inp_sheet).strip().split(".")[0]
    outfile = f'{filename}.txt'
    out=open(outfile,'w')
    out.write("Researcher Name\tResearcher Email\tResult\n")
    ss=ss.dropna(subset=['Researcher Name'])
#    ss['Researcher'] = ss['Researcher Name'].map(lambda x: x.split(' ')[-1])    # get last names
#    ss['Fname'] = ss['Researcher Name'].map(lambda x: x.split(' ')[0])
    ldict=ss.to_dict()
    l={}

    for n in range(len(ss)):
       l[ldict['Researcher Name'][n]]=[ldict['Researcher Email'][n]]

    for k,v in l.items():
        out.write(k+"\t"+v[0]+"\t"+"result\n")

def write_sheet(out_table,researcher,outfile):

    logging.warning(f"Writing file for researcher : {researcher}")
#    out_table = ss.loc[ss.Researcher == researcher, cols]
    out_table = out_table.fillna('')
    out_table.to_csv(outfile, sep=',', index=False)

def process_reffile():

   ref_folder = inpdir     
   for f in os.listdir(ref_folder):
      if f.endswith('.xlsx'):
         inp_sheet=f

      old_path = os.path.join(ref_folder, f)   # Construct the full file path

      new_filename = re.sub(r'\.(?=.*\.)', '', re.sub(r'[\s+\)\(\]\[\/\']+', '', f))    # Remove spaces and parentheses from the filename
      new_path = os.path.join(ref_folder, new_filename)

      os.rename(old_path, new_path)    # Rename the file
      logging.warning(f'Renamed "{old_path}" to "{new_path}"')

   logging.warning(f"Processing sample sheet : {inp_sheet}")
   process_samplesheet(inp_sheet,ref_folder)


if __name__ == "__main__":
   process_reffile()
