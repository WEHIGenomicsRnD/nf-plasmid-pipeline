process CreateSampleSheet {
    label = 'CreateSampleSheet'

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
   
    """
    Plasmid_pipeline.py \
        --inpdir ${infile} \
        --outdir ${outpath} \
        $args
    """
}
