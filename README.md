# Nextflow nf-plasmid-pipeline

A [Nextflow](https://www.nextflow.io/) pipeline for validating and generating plasmid assemblies from the ONT sequencing data.

## Method ##

- The pipeline takes plasmid sample sheet(xlsx format) and reference fasta files. The data can be parsed in different format
     1. As a zip file
     2. As .tar or .tar.gz file
     3. Copy all the files in a directory and add the directory name

- It will unzip/untar the files and create sample sheet for individual user.
- It will do qc check and if any reference file name doesn't exist , it will fail and throw the error.
- The user has to manually change the reference filenames and launch the analysis again
- Epi2me pipeline (https://github.com/WEHIGenomicsRnD/wf-clone-validation-v1.8/) is launched to generate the plasmid assemblies. For each user, epi2me pipeline will run for 3 times to match for consistent assembly size.
- The data is shared to users via HandOver
- The sample QC file having QC status for each sample is shared via email.


## Installation ##

For a manual installation:

```bash
nextflow pull WEHIGenomicsRnD/nf-plasmid-pipeline
```

Note that you would have to set up [Nextflow for private Git repositories](https://www.nextflow.io/blog/2021/configure-git-repositories-with-nextflow.html) for this to work. If this is giving you trouble, just clone the repo in the usual way.

## Configuration ##

Configuration parameters can be found in the `nextflow.config` file.

- `outdir`: directory where the plasmid fastq is present .
- `inpdir`: It supports '.zip/.tar/.tar.gz' files or path where the plasmid sample sheet and reference files are located
- `res_name`: reseracher names to re-launch analysis for selected users or for sharing data via HandOver
- `pipeline_type`: new/relaunch run the analysis for all users or relaunch analysis for selected users 
- `handover` : true/false to share data via handover
- `only_copy`: true/false If you only want to copy data and donot send the email

## Testing (command line) ##

To test the pipeline

- Pull nf-plasmid-pipeline from Github
- python3 .test_build/create_testdata.py (It will create test_data folder in the current directory)
- nextflow run main.nf -profile test,apptainer


### Running the pipeline

```bash
nextflow run WEHIGenomicsRnD/nf-plasmid-pipeline -profile apptainer --inpdir $inp_dir --outdir $outdir
```
## Running ##

### Running on Milton Notes
The following modules need to be loaded before running the pipeline
```
    module load nextflow
```

## Output ##

The pipeline will generate a html report stating the QC status of each sample for all the users.
This can be find under "$outdir/mergeqcstats/*.html" 
