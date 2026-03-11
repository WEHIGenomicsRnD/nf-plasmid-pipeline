/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CreateSampleSheet      } from '../modules/local/sample_sheet/main'
include { UnpackFastq            } from '../modules/local/unpack_fastq/main'
include { UnzipFiles             } from '../modules/local/unzip_files/main'
include { LaunchClonePipe        } from '../modules/local/subpipeline/main'
include { MergeQCStats           } from '../modules/local/merge_stats/main'

include { paramsSummaryMap       } from 'plugin/nf-validation'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_plasmidpipeline_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PLASMIDPIPELINE {

    
    main:

    inpfile = file(params.inpdir, checkIfExists: true)
    subdir = params.subdir.split(',').collect { it.trim().toInteger() }
    pip_ver = params.pip_ver
    sel_users = params.res_name.split(',').collect { it.trim() }

    ch_versions = Channel.empty()

    if (!inpfile.isDirectory() ){
        if(inpfile.name.endsWith('.zip') || inpfile.name.endsWith('.tar') ||  inpfile.name.endsWith('.tar.gz')){
           inpath_ch = UnzipFiles(inpfile, params.outdir).filepath
           ch_versions = ch_versions.mix(UnzipFiles.out.versions)
        }else{
           error "ERROR: File does not exist — inpfile. Either directory or zip files having samplesheet should be given!"
        }
     }else{
        inpath_ch = inpfile
        plasmid_res_ch = Channel.fromPath("${params.outdir}/**/*Pl*id_Batch*.txt" ,checkIfExists: true)
     }

     if (params.pipeline_type == "new"){
         rawsheet_ch = CreateSampleSheet(inpath_ch ,params.outdir).csv_ch
         ch_versions = ch_versions.mix(CreateSampleSheet.out.versions)
         plasmid_res_ch = CreateSampleSheet.out.plasmidtxt_ch

     } else if (params.pipeline_type == "relaunch" && params.res_name != ""){
         Channel.fromPath("${params.outdir}/*.csv")
             .filter { csv ->
                     sel_users.any{ u -> csv.name.contains(u) }
             }.set{rawsheet_ch}
     } else{
        error "ERROR: Please select either new or relaunch as pipeline_type!"
     }

     batchnum= plasmid_res_ch.map{f -> f.baseName}
     rawsheet_ch.view()

     // Untar fastq files //
     UnpackFastq(params.outdir).fastq_path.set{fpath_ch}
     ch_versions = ch_versions.mix(UnpackFastq.out.versions)     

     // Setting sample sheet params for downstream analysis //
     rawsheet_ch.flatten()
                 .combine(fpath_ch)
                 .map{ it, fpath  ->
                   def res = []
                   for (x in subdir){
                     if (it.name.contains("withoutref")){
                        def rname = it*.simpleName[-1].replace("_withoutref","")
                        res << tuple("${params.outdir}/${rname}_${pip_ver}/withoutref/", it , x, fpath)
                     }
                     else{
                        res << tuple("${params.outdir}/${it.baseName}_${pip_ver}/", it ,x, fpath )
                     }
                   }
                   res
                   }.flatMap{ it }.set{ssheet_ch}

     ssheet_ch.view()

     // Launch clone validation pipeline //
     qcinput_ch = LaunchClonePipe(ssheet_ch).qcfile_ch.collect()
     ch_versions = ch_versions.mix(LaunchClonePipe.out.versions)

     // Channel for merging QC stats //
     ch_qc = MergeQCStats(batchnum, qcinput_ch).mergedqc_ch
     ch_versions = ch_versions.mix(MergeQCStats.out.versions)


     if(params.handover) {
         plasmid_res_ch
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
                      def email = row[1].split('@')[0]
                      tuple(row[0], email, row[2], batch, rdate)
                    }
                  }.filter { tup ->
                       sel_users.any{u -> tup[3].contains(u)}
                  }.view()

     }

     emit:
     mergedqc_file = ch_qc
     versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
