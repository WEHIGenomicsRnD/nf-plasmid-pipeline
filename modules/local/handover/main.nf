process HandOver{
   tag 'HandOver'
   label 'process_medium'

   publishDir params.outdir, mode: 'copy'

   input:
   tuple val(mail), val(resfolder), val(batch), val(rundate)

   output:
   path  "versions.yml"     , emit: versions

   script:
   def args = task.ext.args ?: ''
   def handover_path = params.handover_path ? params.handover_path : ""
   def outdir = params.outdir ? params.outdir : ""

   """
   cd $outdir
   rsync -av ${outdir}/${rundate}_${mail}_v1.8.0/${resfolder}/* ${handover_path}/${mail}_${rundate}-Plasmid${batch}/
   chmod 700 ${handover_path}/${mail}_${rundate}-Plasmid${batch}/
   tar -P -cvzf ${rundate}_${mail}_v1.8.0.tar.gz ${rundate}_${mail}_v1.8.0/${resfolder}/
   rsync -av ${outdir}/${rundate}_${mail}_v1.8.0.tar.gz /stornext/Projects/promethion/promethion_access/lab_bowden/G000309_plasmid-sequencing/long_term/analysis/
   cd -
  
   cat <<-END_VERSIONS > versions.yml
   "${task.process}":
        tar: \$(tar --version | sed 's/tar (GNU tar) //g')
        rsync: \$(rsync --version | sed 's/rsync  version //g')
   END_VERSIONS
   """
 
   stub:
   """
   cat <<-END_VERSIONS > versions.yml
   "${task.process}":
        tar: \$(tar --version | sed 's/tar (GNU tar) //g')
        rsync: \$(rsync --version | sed 's/rsync  version //g')
   END_VERSIONS
   """
}
