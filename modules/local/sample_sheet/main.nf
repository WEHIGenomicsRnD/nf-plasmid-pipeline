process CreateSampleSheet {
    tag 'CreateSampleSheet'
    label 'process_medium'


    container 'community.wave.seqera.io/library/natsort_pandas_numpy_openpyxl_pruned:d17f0440b85f9b65'

    input:
    val infile
    val outpath

    output:
    path "*.csv", emit: csv_ch
    path "*.txt" , emit: plasmidtxt_ch
    path  "versions.yml"    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    Plasmid_pipeline.py \
        --inpdir ${infile} \
        --outdir ${outpath} \
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch ${infile.baseName}.csv
    touch ${infile.baseName}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
