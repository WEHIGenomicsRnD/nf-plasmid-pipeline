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
    path  "versions.yml"   , emit: versions

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

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
