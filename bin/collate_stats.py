#!/usr/bin/env python
import pandas as pd
import sys
from argparse import ArgumentParser
from collections import defaultdict

import os

def parse_args():
    '''Parse arguments'''
    description = '''
        Merge sample_QC files for all users

        Usage:
            collate_stats.py <qc_files>

        Outputs a table of merged QC file
        '''
    parser = ArgumentParser(description=description)
    parser.add_argument('qc_files',
                        nargs='+',
                        type=str,
                        help='QC files to merge')

    return parser.parse_args()


def merge_files(cfile,result_df):
   sname,num,name=os.path.basename(cfile).strip().split("-")
   df = pd.read_csv(cfile, sep='\t')
   if len(result_df) == 0:
      result_df = df
   else:
      onval=['SampleId','QC method','Size(User derfined)','Size(Raw fastq)']
      result_df = pd.merge(result_df, df, how='outer', on=onval)

   result_df.rename(columns={result_df.columns[-1]: f"{sname}-{num}-Status"}, inplace=True)
   result_df.rename(columns={result_df.columns[-2]: f"{sname}-{num}-Assembly Size"}, inplace=True)

   return result_df


def bg_color(val):
    """
    Colors the background of a cell based on its value.
    Returns a CSS 'attribute: value' string.
    """
    if 'PASS' in val:
        return 'background-color: #09C816'
    elif 'FAIL' in val:
        return 'background-color: #FA8FAB'
    elif 'Failed' in val:
        return 'background-color: #FA8FAB'
    elif 'WARNING:' in val:
        return 'background-color: #F6FA8F'
    elif 'infered' in val:
        return 'background-color: #F6FA8F'
    else:
        # Return empty string for no styling
        return ''


def main():
    args = parse_args()

    cnt=1
    snames=[]
    groups = defaultdict(list)
    out=open("merged_stats.txt",'w')
    html_file=open('output.html', 'w')
    for count_file in args.qc_files:
        sname=os.path.basename(count_file).strip().split("-")[0]
        if sname in snames:
            cnt=cnt+1
            groups[sname]=merge_files(count_file,groups[sname])
        else:
            groups[sname]= pd.DataFrame()
            snames.append(sname)
            groups[sname]=merge_files(count_file,groups[sname])
   
    print(f"{cnt}")
    for i, grp in enumerate(groups):
       empty_row = pd.DataFrame([[None]*len(groups[grp].columns)], columns=groups[grp].columns)
       new_grp = pd.concat([groups[grp], empty_row], ignore_index=True)
       new_grp.to_csv(out, sep='\t', index=False)
       new_df = groups[grp].reset_index(drop=True)

       print(f"{new_df}")
       if cnt >1:
          run_cols = new_df.columns[[5,7,9]]
       else:
          run_cols = new_df.columns[[5]]

       cols_to_int = new_df.columns[[2, 3,4]]
       new_df[cols_to_int] = new_df[cols_to_int].astype(int)

       styled_df = (
            new_df.style
#            .applymap(bg_color, subset=run_cols)
            .set_table_attributes('style="border-collapse:collapse"')
            .set_table_styles([
          {'selector': 'table', 'props': [('table-layout', 'fixed'),('width', '1800px')]},
          {'selector': 'td', 'props': [('border', '1px solid black'),('overflow-wrap', 'break-word'),('width', '200px'),('padding', '2px')]},
          {'selector': 'th', 'props': [('border', '1px solid black'),('overflow-wrap', 'break-word'),('width', '200px'),('padding', '2px'),('background-color','#BBD7FC')]}
         ]).hide(axis='index')\
           .apply(lambda x: ['background-color: #ffffff' if i%2==0 else 'background-color: #f2f2f2' for i in range(len(x))], axis=0)     
           .applymap(bg_color, subset=run_cols)
       )
       html_out = styled_df.to_html(index=False)

       if i>0:
          html_file.write("<br><br>")

       html_file.write(html_out)

    out.close()
    html_file.close()



if __name__ == "__main__":
    main()
