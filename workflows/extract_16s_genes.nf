// ===================================
// EXTRACT 16S GENES FROM WHOLE GENOME
// ===================================
process get_16S_reads {
    conda 'container-files/rad_nextflow_conda.yml'

    input:
    path filePath
    val accessionName

    output:
    path "16S-hits/${accessionName}/gff3_${accessionName}.gff3", emit: rrna_16S_gff3s
    path "16S-hits/${accessionName}/16S_${accessionName}.fna", emit: rrna_16S_fastas, optional: true

    script:
    """
    mkdir -p 16S-hits/${accessionName} 
    output_file="16S-hits/${accessionName}/16S_${accessionName}.fna"
    touch \$output_file
    barrnap --kingdom bac ${filePath} -outseq 16S-hits/${accessionName}/temp_16S_${accessionName}.fna \
        > 16S-hits/${accessionName}/gff3_${accessionName}.gff3
    seqkit grep -nr -p "16S" 16S-hits/${accessionName}/temp_16S_${accessionName}.fna > 16S-hits/${accessionName}/16S_${accessionName}.fna
    if [[ ! -s 16S-hits/${accessionName}/16S_${accessionName}.fna ]]; then
        echo "No 16S genes were found in ${accessionName}. Removing file"
        rm 16S-hits/${accessionName}/16S_${accessionName}.fna
    fi
    """

}


// ===================================
// WORKFLOW
// ===================================

workflow EXTRACT_16S_RRNA_GENES{
    take:
    data_dir

    main:
    fastaChannel = data_dir
                    .flatMap {dir -> file("${dir}/**/*.fna")}
    accessionNames = fastaChannel
                        .flatMap {file -> file.parent.getName()}

    reads = get_16S_reads(fastaChannel, accessionNames)
    reads_16S_fastas = reads.rrna_16S_fastas
    reads_16S_gff3s = reads.rrna_16S_gff3s
    // TODO: reformat fastas to follow ">accession:base-range" convention
    // all16Scopies = bedtools_call(gff2Files, fastaChannel)

    emit:
    // fastaFile
    reads_16S_fastas
    reads_16S_gff3s
    // all16Scopies
}
