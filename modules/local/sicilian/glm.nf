// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

// TODO nf-core: If in doubt look at other nf-core/modules to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/software
//               You can also ask for help via your pull request or on the #modules channel on the nf-core Slack workspace:
//               https://nf-co.re/join

// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided as a string i.e. "options.args"
//               where "params.options" is a Groovy Map that MUST be provided via the addParams section of the including workflow.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
// TODO nf-core: Software that can be piped together SHOULD be added to separate module files
//               unless there is a run-time, storage advantage in implementing in this way
//               e.g. it's ok to have a single module for bwa to output BAM instead of SAM:
//                 bwa mem | samtools view -B -T ref.fasta
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, "fake files" MAY be used to work around this issue.

params.options = [:]
options        = initOptions(params.options)

process SICILIAN_GLM {
    tag "$sample_id"
    label 'process_medium'
    label 'cpu_2'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:[:], publish_by_meta:[]) }

    // TODO nf-core: List required Conda package(s).
    //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    //               For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation on different operating systems.
    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda (params.enable_conda ? "bioconda::bioconductor-genomicalignments=1.22.0 conda-forge::r-tidyverse=1.3.1 conda-forge::r-glmnet=4.1conda-forge::r-tictoc=1.0 dloewenstein::r-cutpointr=1.0.0 conda-forge::r-data.table=1.14.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE"
    } else {
        container "docker.io/czbiohub/sicilian:dev"
    }

    input:
    // TODO nf-core: Where applicable all sample-specific information e.g. "id", "single_end", "read_group"
    //               MUST be provided as an input via a Groovy Map called "meta".
    //               This information may not be required in some instances e.g. indexing reference genome files:
    //               https://github.com/nf-core/modules/blob/master/software/bwa/index/main.nf
    // TODO nf-core: Where applicable please provide/convert compressed files as input/output
    //               e.g. "*.fastq.gz" and NOT "*.fastq", "*.bam" and NOT "*.sam" etc.
    path gtf
    path domain
    path exon_bounds
    path splices
    tuple val(sample_id), path(class_input), path(sj_out_tab), path(chimeric_out_junction), path(reads_per_gene)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(sample_id), path("*GLM_output.txt"), emit: glm_output
    tuple val(sample_id), path("*sicilian_called_splice_juncs.tsv"), emit: sicilian_called_splices
    // TODO nf-core: List additional required output channels/values here
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    
    // TODO nf-core: Where possible, a command MUST be provided to obtain the version number of the software e.g. 1.10
    //               If the software is unable to output a version number on the command-line then it can be manually specified
    //               e.g. https://github.com/nf-core/modules/blob/master/software/homer/annotatepeaks/main.nf
    // TODO nf-core: It MUST be possible to pass additional parameters to the tool as a command-line string via the "$options.args" variable
    // TODO nf-core: If the tool supports multi-threading then you MUST provide the appropriate parameter
    //               using the Nextflow "task" variable e.g. "--threads $task.cpus"
    // TODO nf-core: Please replace the example samtools command below with your module's command
    // TODO nf-core: Please indent the command appropriately (4 spaces!!) to help with readability ;)
    def outdir = './'
    def single = (params.single_end || params.tenx) ? '1' : '0'
    def tenx = params.tenx ? '1' : '0'
    def stranded = params.stranded ? '1' : '0'
    """
    ls -lha
    GLM_script_light.R \\
        $outdir \\
        $gtf \\
        $single \\
        $tenx \\
        $stranded \\
        $domain \\
        $exon_bounds \\
        $splices

    ls -lha
    # Rename file to be unique to each sample to prevent clashing
    mv GLM_output.txt ${sample_id}__GLM_output.txt
    mv sicilian_called_splice_juncs.tsv  ${sample_id}__sicilian_called_splice_juncs.tsv 

    # Output R package versions
    Rscript -e 'cat(paste(packageVersion("cutpointr")))' > ${software}__r-cutpointr.version.txt
    Rscript -e 'cat(paste(packageVersion("data.table")))' > ${software}__r-data.table.version.txt
    Rscript -e 'cat(paste(packageVersion("dplyr")))' > ${software}__r-dplyr.version.txt
    Rscript -e 'cat(paste(packageVersion("GenomicAlignments")))' > ${software}__bioconductor-GenomicAlignments.version.txt
    Rscript -e 'cat(paste(packageVersion("glmnet")))' > ${software}__r-glmnet.version.txt
    Rscript -e 'cat(paste(packageVersion("stringr")))' > ${software}__r-stringr.version.txt
    Rscript -e 'cat(paste(packageVersion("tictoc")))' > ${software}__tictoc.version.txt
    """
}
