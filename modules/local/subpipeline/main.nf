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
    def pipelineCacheDir = "${projectDir}/.nxf_shared_pipeline_assets"

    """

     module load nextflow/24.04.2
     rm -rf ${subdir}/result${num}

     export NXF_ASSETS="${pipelineCacheDir}"
     mkdir -p "\${NXF_ASSETS}"

     echo "Checking pipeline asset cache..."
     LOCK_DIR="\${NXF_ASSETS}/repository.lock"

     while ! mkdir "\${LOCK_DIR}" 2>/dev/null; do
        echo "Another sample job is pulling the repository. Waiting 10 seconds..."
        sleep 10
    done

    # --- CRITICAL SECTION: Only one SLURM job is here at a time ---
    if [ ! -d "\${NXF_ASSETS}/WEHIGenomicsRnD/wf-clone-validation-v1.8" ]; then
        echo "Cache miss. Safely downloading pipeline repository..."
        nextflow pull WEHIGenomicsRnD/wf-clone-validation-v1.8
    else
        echo "Cache hit! Using existing local pipeline code."
    fi

    # Release the lock by deleting the directory
    rmdir "\${LOCK_DIR}"


     NXF_SANDBOX="${subdir}/.nxf_cache_sample_${num}"
     rm -rf \${NXF_SANDBOX}
     mkdir -p \${NXF_SANDBOX}/nxf_home
     mkdir -p \${NXF_SANDBOX}/work
#     nextflow pull WEHIGenomicsRnD/wf-clone-validation-v1.8

     export NXF_HOME=\${NXF_SANDBOX}/nxf_home
     export NXF_LOG_FILE=\${NXF_SANDBOX}/engine_internal.log
  
     rm -rf ${subdir}/result${num}

     nextflow run WEHIGenomicsRnD/wf-clone-validation-v1.8  \
         -w \${NXF_SANDBOX}/work \
         --fastq ${fpath}/fastq_pass \
         --sample_sheet ${ssheet} \
         --out_dir ${subdir}/result${num} \
         --db_directory ${params.db_dir} \
         --override_basecaller_cfg ${params.model} \
         -name clone-validation-${num} \
         -c ${projectDir}/conf/slurm_plasmid.config \
               -profile slurm \
         $args

     cp ${subdir}/result${num}/sample_QC.txt ${sname}-sample_QC.txt

     rm -rf \${NXF_SANDBOX}

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
