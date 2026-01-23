process UnpackFastq{
   label "Unpack_Fastq"

   input:
   path(fpath) 
   val(sample)

   output:
   path"${fpath}/extracted_tar/${sample}/*" , emit : fastq_path

   when:
   task.ext.when == null || task.ext.when

   script:
   def args = task.ext.args ?: ''
   """
 
   if [ ! -d "${fpath}/extracted_tar/${sample}" ];then
      mkdir -p ${fpath}/extracted_tar
      
      if [ ! -L ${fpath}/*fastq_pass.tar ];then
         ln -s ${fpath}/fastq/*fastq_pass.tar ${fpath}
      fi

      tar -xvf ${fpath}/*_fastq_pass.tar -C ${fpath}/extracted_tar/
   fi


   """
   
}


process UnzipFiles{
   label "Unzip_Files"

   input:
   val(fpath) 
   path(outpath)

   output:
   path"${outpath}/ref/" , emit : filepath

   when:
   task.ext.when == null || task.ext.when

   script:
   def args = task.ext.args ?: ''
   """
   if [ -d "${outpath}/ref" ];then
      rm -rf ${outpath}/ref
   fi
   mkdir -p ${outpath}/ref
   if [ ${fpath}=~*.zip ];then
      unzip ${fpath} -d ${outpath}/ref

   elif [ ${fpath}=~*.tar ];then
      tar -xvf ${fpath} -C ${outpath}/ref

   elif [ ${fpath}=~*.tar.gz ];then
      tar -xvzf ${fpath} -C ${outpath}/ref

   else
      error "Unknown File type"
   fi

   """

}





process LaunchClonePipe{
    label "Clone_Pipeline"

    input:
    tuple val(subdir) , path(ssheet), val(num), val(fpath)

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """

     rm -rf ${subdir}/result${num}

     nextflow run WEHIGenomicsRnD/wf-clone-validation-v1.8 \
         --fastq ${fpath}/fastq_pass \
         --sample_sheet ${ssheet} \
         --out_dir ${subdir}/result${num} \
         --db_directory ${params.db_dir} \
         --override_basecaller_cfg ${params.model} \
         -c /stornext/Home/data/allstaff/g/gupta.i/Plasmid-pipeline/slurm_plasmid.config \
         -profile slurm \
         $args

    """
}
