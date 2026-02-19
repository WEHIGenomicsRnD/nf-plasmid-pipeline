#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { CreateSampleSheet } from './modules/createsheet.nf'
include { MergeQCStats } from './modules/createsheet.nf'
include  { LaunchClonePipe   } from './modules/subpipeline.nf'
include  { UnpackFastq   } from './modules/subpipeline.nf'
include  { UnzipFiles   } from './modules/subpipeline.nf'

infile = file(params.inpdir)
pip_ver = params.pip_ver
outdir = params.outdir
subdir = params.subdir.split(',').collect { it.trim().toInteger() }
sel_users = params.res_name.split(',').collect { it.trim() }

workflow {

     if (!infile.isDirectory() ){
        if(infile.name.endsWith('.zip') || infile.name.endsWith('.tar') ||  params.infile.name.endsWith('.tar.gz')){
           inpath_ch = UnzipFiles(infile, outdir).filepath
        }else{
           error "ERROR: File does not exist — ${params.input}. Either directory or zip files having samplesheet should be given!"
        }
      }else{
        inpath_ch = infile
      }

     if (params.pipeline_type == "new"){
         ssheet = CreateSampleSheet(inpath_ch ,outdir)
         rawsheet_ch = ssheet.csv_ch

     } else if (params.pipeline_type == "relaunch" && params.res_name != ""){
         Channel.fromPath("${params.outdir}/*.csv")
             .filter { csv ->
                     sel_users.any{ u -> csv.name.contains(u) }
             }.set{rawsheet_ch}
     } else{
         Channel.fromPath("${params.outdir}/*.csv")
                .collect()
                .set{rawsheet_ch}
     }

     rawsheet_ch.view()
     Channel.fromPath(params.outdir)
           .map {fpath ->
              def sample = fpath.getName().split('_').findAll { it }[1]
           }.set{sample_ch}


     UnpackFastq(params.outdir,sample_ch).fastq_path.set{fpath_ch}

     rawsheet_ch.flatten()
                 .combine(fpath_ch)
                 .map{ it, fpath  -> 
                   def res = []
                   for (x in subdir){
                     if (it.name.contains("withoutref")){
                        def rname = it*.simpleName[-1].replace("_withoutref","")
                        res << tuple("${outdir}/${rname}_${pip_ver}/withoutref/", it , x, fpath)
                     }
                     else{
                        res << tuple("${outdir}/${it.baseName}_${pip_ver}/", it ,x, fpath )
                     }
                   }
                   res
                   }.flatMap{ it }.set{ssheet_ch}

     ssheet_ch.view()

     qcinput_ch = LaunchClonePipe(ssheet_ch).qcfile_ch.collect()

     Channel.fromPath("${params.outdir}/*Pl*id_Batch*.txt" ,checkIfExists: true)
            .map{f -> f.baseName}.set{batchnum}
     MergeQCStats(batchnum, qcinput_ch)

     if(params.handover) {
          Channel.fromPath("${params.outdir}/*Pl*id_Batch*.txt" ,checkIfExists: true)
                 .map { file ->
                        def batch = (file.name =~ /(Batch\d+)/)[0][1]
                        def rdate = file.name.split('_')[0]
                        tuple(file, batch, rdate)
                 }
                 .flatMap { file, batch, rdate ->
                      file
                       .splitCsv(sep: '\t')
                       .collect { row -> tuple(row, batch, rdate) }
                  }
                 .map { row ,batch, rdate ->
                   if (row[0].trim() != 'Researcher Name') {
//                      def fname = row[0].split(" ")[0]
//                      def lname = row[0].split(" ")[-1]
//                      def mname = "${lname}${fname[0..1]}"
                      def email = row[1].split('@')[0]
                      tuple(row[0], email, row[2], batch, rdate)
                    }
                  }.filter { tup ->
                       sel_users.any{u -> tup[3].contains(u)} 
                  }.view() 

     }  
  
}
