process SendEmail {
    label 'SendEmail'


//    container 'community.wave.seqera.io/library/natsort_pandas_numpy_openpyxl_pruned:825ddd073161283c'
    container 'community.wave.seqera.io/library/natsort_pandas_numpy_openpyxl_pruned:4f750799cf79af84'

    input:
    val infile
    val outpath

    output:
    path  "versions.yml"   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def res_name  = params.res_name ? params.res_name : ""
    def mon_yaml  = params.config_yaml ? params.config_yaml : ""

    """

    send_email_v2.py \
        --resname ${res_name} \
        --inpfile ${infile} \
        --resdir ${outpath} \
        --config ${mon_yaml} \
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
