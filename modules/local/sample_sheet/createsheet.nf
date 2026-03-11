process CreateSampleSheet {
    label = 'CreateSampleSheet'


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

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch ${infile.baseName}.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}



process MergeQCStats {
    label = 'MergeQCStats'


    container 'community.wave.seqera.io/library/natsort_pandas_numpy_openpyxl_pruned:d17f0440b85f9b65'

    input:
    val(batchnum)
    path(infile)

    output:
    path "*.txt", emit: mergedqc_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    collate_stats.py \
        ${infile}

    cp merged_stats.txt ${batchnum}.QCFile.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch merged_stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
