process MergeQCStats {
    label = 'MergeQCStats'


//    container 'community.wave.seqera.io/library/natsort_pandas_numpy_openpyxl_pruned:d17f0440b85f9b65'
    container 'community.wave.seqera.io/library/natsort_pandas_numpy_openpyxl_pruned:825ddd073161283c'

    input:
    val(batchnum)
    path(infile)

    output:
    path "*.txt", emit: mergedqc_ch
    path "${batchnum}.html", emit:html_ch
    path  "versions.yml"    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    collate_stats.py \
        ${infile}

    cp merged_stats.txt ${batchnum}.QCFile.txt
    cp output.html ${batchnum}.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch ${batchnum}.QCFile.txt
    touch ${batchnum}.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
