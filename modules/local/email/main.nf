process SendEmail {
    tag 'SendEmail'
    label 'process_medium'


//    container 'community.wave.seqera.io/library/natsort_pandas_numpy_openpyxl_pruned:825ddd073161283c'
//    container 'community.wave.seqera.io/library/natsort_pandas_numpy_openpyxl_pruned:4f750799cf79af84'

    input:
    val infile
    val outpath
    val res_name

    output:
    path  "versions.yml"   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def mon_yaml  = params.config_yaml ? params.config_yaml : ""
    def email_cc = params.email_cc ? params.email_cc : ""
    def email_from   = params.email_from ? params.email_from : ""

    """

    send_email_v2.py \
        --resname ${res_name} \
        --inpfile ${infile} \
        --resdir ${outpath} \
        --config ${mon_yaml} \
        --email_cc "${email_cc}" \
        --email_from ${email_from} \
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
