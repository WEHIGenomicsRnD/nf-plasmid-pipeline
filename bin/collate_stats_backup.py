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
      onval=['SampleId','Size(User derfined)','Size(Raw fastq)']
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
        return 'color: green'
    elif 'FAIL' in val:
        return 'color: red'
    elif 'Failed' in val:
        return 'color: red'
    elif 'WARNING:' in val:
        return 'color: orange'
    elif 'infered' in val:
        return 'color: orange'
    else:
        # Return empty string for no styling
        return ''


def main():
    args = parse_args()

    snames=[]
    groups = defaultdict(list)
    out=open("merged_stats.txt",'w')
    for count_file in args.qc_files:
        sname=os.path.basename(count_file).strip().split("-")[0]
        if sname in snames:
            groups[sname]=merge_files(count_file,groups[sname])
        else:
            groups[sname]= pd.DataFrame()
            snames.append(sname)
            groups[sname]=merge_files(count_file,groups[sname])


    for grp in groups:
       empty_row = pd.DataFrame([[None]*len(groups[grp].columns)], columns=groups[grp].columns)
       new_grp = pd.concat([groups[grp], empty_row], ignore_index=True)
       new_grp.to_csv(out, sep='\t', index=False)
       new_df = groups[grp]


    new_df = pd.read_csv("merged_stats.txt",sep="\t")
    new_df= new_df.fillna('-')
    run_cols = new_df.columns[[4,6,8]]

    styled_df = (
            new_df.style
            .applymap(bg_color, subset=run_cols)
            .set_table_styles([
          {'selector': 'th, td', 'props': [('border', '1px solid black'),('white-space', 'nowrap')]},
          {'selector': 'table', 'props': [('border-collapse', 'collapse'),('border-spacing', '0'),('table-layout', 'fixed'),
           ('width', '700px')]}
      ])
    )
    html_out = styled_df.to_html(index=False)


    with open('output.html', 'w') as file:
       file.write(html_out)



if __name__ == "__main__":
    main()
