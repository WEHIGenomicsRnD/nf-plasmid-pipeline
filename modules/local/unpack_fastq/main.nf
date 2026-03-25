process UnpackFastq{
   label "Unpack_Fastq"

   input:
   path(fpath)

   output:
   path"${fpath}/extracted_tar/*/*" , emit : fastq_path
   path  "versions.yml"         , emit: versions

   when:
   task.ext.when == null || task.ext.when

   script:
   def args = task.ext.args ?: ''
   """

   if [ ! -d "${fpath}/extracted_tar/" ];then
      mkdir -p ${fpath}/extracted_tar

      if [ ! -L ${fpath}/*fastq_pass.tar ];then
         ln -s ${fpath}/fastq/*fastq_pass.tar .
      fi

      tar -xvf *fastq_pass.tar -C ${fpath}/extracted_tar/
   fi

   cat <<-END_VERSIONS > versions.yml
   "${task.process}":
       tar: \$(tar --version | sed 's/tar (GNU tar)//g')
   END_VERSIONS
   """

   stub:
   """
   cat <<-END_VERSIONS > versions.yml
   "${task.process}":
       tar: \$(tar --version | sed 's/tar (GNU tar)//g')
   END_VERSIONS
    """
}
