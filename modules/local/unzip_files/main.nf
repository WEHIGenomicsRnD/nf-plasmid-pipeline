process UnzipFiles{
   label "Unzip_Files"

   input:
   val(fpath)
   path(outpath)

   output:
   path"${outpath}/ref/" , emit : filepath
   path  "versions.yml"     , emit: versions

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

   cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tar: \$(tar --version | sed 's/tar (GNU tar)//g')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p "${outpath}/ref"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tar: \$(tar --version | sed 's/tar (GNU tar)//g')
    END_VERSIONS

   """

}
