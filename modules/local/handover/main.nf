process HandOver{
   label = "HandOver"

   publishDir params.outdir, mode: 'copy'

   input:
   tuple val(name), val(researcher), val(resfolder), val(mail), val(batch), val(rundate)

   output:
   path  "versions.yml"     , emit: versions

   script:
   def args = task.ext.args ?: ''
   def handover_path = params.handover_path ? params.handover_path : ""

   """
    rsync -av ${rundate}_${researcher}_v1.8.0/${resfolder}/* ${handover_path}/${mail}_${rundate}-Plasmid${batch}/
    chmod 700 ${handover_path}/${mail}_${rundate}-Plasmid${batch}/
    tar cvzf ${rundate}_${researcher}_v1.8.0.tar.gz ${rundate}_${researcher}_v1.8.0/${resfolder}/
    rsync -av ${rundate}_${researcher}_v1.8.0.tar.gz /stornext/Projects/promethion/promethion_access/lab_bowden/G000309_plasmid-sequencing/long_term/analysis/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tar: \$(tar --version | sed 's/tar (GNU tar)//g')
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
