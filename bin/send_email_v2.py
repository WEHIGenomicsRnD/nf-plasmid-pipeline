#!/usr/bin/env python

import os
import argparse
import pandas as pd
import numpy as np
import zipfile
import re
import yaml
import requests
from datetime import datetime, timedelta


parser = argparse.ArgumentParser()
#parser.add_argument('-f','--file', help='Sample sheet file')
parser.add_argument('-r','--resname', help='Researcher Name')
parser.add_argument('-i','--inpfile', help='Input Text file')
parser.add_argument('-p','--resdir', help='Analysis Result dir')
parser.add_argument('-c','--config', help='Config File')

args = parser.parse_args()
#inp_sheet=args.file
resname=args.resname.strip().split(" ")
inp_sheet=args.inpfile
resdir=args.resdir
mon_config=args.config

stream = open(mon_config, 'r')
cnfg = yaml.load(stream, yaml.SafeLoader)

apikey = cnfg['apikey']
apiUrl = cnfg["apiUrl"]
headers = {"Authorization" : apikey,
           "API-Version" : '2024-01'}

ufrom=cnfg["from"]
cc=cnfg["cc"]




if not inp_sheet:
   raise SystemExit(1)
   print(f"WARN: Input text file is required!")

if not resname:
   print(f"WARN: Please give researcher name!") ## List of researcher name to send email
   raise SystemExit(1) 

if not resdir:
   print(f"WARN: Please give path to analysis result!") ## Analysis path
   raise SystemExit(1)


pdate,name,bname=os.path.basename(inp_sheet).strip().split(".")[0].split("_")  ## Fetching Batch number from Excel sheet name
batch_num=bname.replace("Batch","")
enddate=(datetime.now() + timedelta(days=3) ).strftime('%A %d %b')    ## End date for sending email
## Process the input sample sheet and create researcher wise csv files ###
     

l={}
with open (inp_sheet) as infile:
    for f in infile.readlines():
        if f.startswith("Researcher"):
            continue
        line=f.split("\t")
        fname=line[0].split(" ")[0]
        rname=line[1].split("@")[0]
        l[rname]=[line[1],fname,line[2]]



def get_message(res,fname):
    folder=f'{pdate}_{res}_v1.8.0/'
    message=f"{bname} plasmid validation v1.8.0 {res}\n\nHi {fname},\n\nThe samples have been processed. Please see attached file for sample QC.\n\nThe results are shared via Handover and you will receive separate email about the folder details. In the results folder, you will find your validation report (wf-clone-validation-report.html), run data, final assemblies, read alignment to the assemblies, alignment of the assemblies to your reference .fasta file and the variants called from it (if reference provided).\n\nPlease respond to this email if you need the raw fastq files\n\nPlease let me know for any queries.\n\nThank You\nInna"
    return message




def get_monday_email():
    bnum=f"Plasmid Batch {batch_num}"
#    bnum="Plasmid batch 132"
    bquery='{items_page_by_column_values (board_id: 1950936703,columns: {column_id: "name", column_values: ["'+bnum+'"]}) { cursor items { id name email } }}'
    data = {'query' : bquery}
    r = requests.post(url=apiUrl, json=data, headers=headers)
#    print(r.json())
    content=r.json()['data']['items_page_by_column_values']['items']
    if content:
        bcc=f" -b {content[0]['email']}"
    else:
        bcc=""
    return bcc

def send_email():
   for res in resname:
      resfolder=l[res][2].strip()
      qc_file = f"{resdir}/{pdate}_{res}_v1.8.0/{resfolder}/sample_QC.txt"
      print(f"{qc_file}")
      if os.path.exists(qc_file):
          att=f" -a {qc_file}"
      else:
          att=""

      to=l[res][0]
      fname=l[res][1]
      subj=f"{bname} plasmid validation v1.8.0 {res}"
      msg=get_message(res,fname)
      bcc=get_monday_email()
      cmd=f"echo '{msg}' | mailx {att} -r {ufrom} {bcc} -s '{subj}' -c {cc} {to}"
#      cmd=f"echo '{msg}' | mailx {att} -r {ufrom} -s '{subj}' -c {cc} {to}"
      print(cmd)
#      os.system(cmd)



if __name__ == "__main__":
        send_email()
