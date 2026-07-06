process LaunchClonePipe{
    "label 'process_medium'"

    tag "${ssheet.baseName}-${num}"

    clusterOptions = '--export=NONE'

    input:
    tuple val(subdir) , path(ssheet), val(num), val(fpath)

    output:
    path "*sample_QC.txt", emit: qcfile_ch
    path  "versions.yml"      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def sname = "${ssheet.baseName}-${num}"

    """

     module load nextflow/24.04.2
     rm -rf ${subdir}/result${num}

     # Isolate sub-pipeline from Seqera environment
      unset TOWER_ACCESS_TOKEN
      unset TOWER_WORKFLOW_ID
      unset NXF_OPTS

      export NXF_HOME=\${PWD}/.nextflow_clone
      export NXF_WORK=\${PWD}/.nf_work_clone

     nextflow run WEHIGenomicsRnD/wf-clone-validation-v1.8 \
         --fastq ${fpath}/fastq_pass \
         --sample_sheet ${ssheet} \
         --out_dir ${subdir}/result${num} \
         --db_directory ${params.db_dir} \
         --override_basecaller_cfg ${params.model} \
         -name clone-validation-${num} \
         -c ${projectDir}/conf/slurm_plasmid.config \
               -profile slurm \
         -ansi-log false \
         -offline \
         $args

     cp ${subdir}/result${num}/sample_QC.txt ${sname}-sample_QC.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextflow: \$(nextflow -v | sed 's/nextflow version //g')
    END_VERSIONS
    """

    stub:
    """
    touch F${num}-sample_QC.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextflow: \$(nextflow -v | sed 's/nextflow version //g')
    END_VERSIONS
    """
}
