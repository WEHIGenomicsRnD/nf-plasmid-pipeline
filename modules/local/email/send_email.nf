process SendEmail {
    label = 'SendEmail'

    publishDir params.outdir, mode: 'copy'

    container 'community.wave.seqera.io/library/natsort_pandas_numpy_openpyxl_pruned:d17f0440b85f9b65'

    input:
    val infile
    val outpath

    output:
    path "*.csv", emit: csv_ch
    path "*.txt"

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def only_copy = params.only_copy ? "--only_copy" : ""
    def res_name  = params.res_name ? params.res_name : ""
   
    """
    send_email_v2.py \
        --resname ${res_name} \
        --inpfile ${infile} \
        --resdir ${outpath} \
        $only_copy \
        $args
    """
}

process HandOver{
   label = "HandOver"   

   publishDir params.outdir, mode: 'copy'

   input:
   tuple val(name), val(researcher), val(resfolder), val(mail), val(batch), val(rundate)

   script:
   def args = task.ext.args ?: ''
   def handover_path = params.handover_path ? params.handover_path : "" 

   """
    rsync -av ${rundate}_${researcher}_v1.8.0/${resfolder}/* ${handover_path}/${mail}_${rundate}-Plasmid${batch}/
    chmod 700 ${handover_path}/${mail}_${rundate}-Plasmid${batch}/
    tar cvzf ${rundate}_${researcher}_v1.8.0.tar.gz ${rundate}_${researcher}_v1.8.0/${resfolder}/ ${rundate}_${researcher}.csv
    rsync -av ${rundate}_${researcher}_v1.8.0.tar.gz /stornext/Projects/promethion/promethion_access/lab_bowden/G000309_plasmid-sequencing/long_term/analysis

   """

}
