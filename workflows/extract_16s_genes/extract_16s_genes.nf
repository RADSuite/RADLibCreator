// ===================================
// EXTRACT 16S GENES FROM WHOLE GENOME
// ===================================


process filter_gff3 {
    input:
    tuple path(fasta), path(gff2File), val(accession)

    output:
    tuple path(fasta), path("${accession}/filtered_${accession}.gff"), val(accession)

    script:
    """
    mkdir ${accession} && touch ${accession}/filtered_${accession}.gff 
    awk -F'\t' '\$3 == "rRNA" && \$9 ~ /16S/' $gff2File > ${accession}/filtered_${accession}.gff 
    """
}

process extract_reads {
    input:
    tuple path(fasta), path(filteredGff3), val(accession)

    output:
    path "${accession}/${accession}_16S_genes.fna", optional: true // there may not be any documented 16S genes in this accession

    script:
    """
    mkdir ${accession} && touch "${accession}/${accession}_16S_genes.fna"
    bedtools getfasta -s -fi ${fasta} -bed ${filteredGff3} > "${accession}/${accession}_16S_genes.fna"
    if [[ ! -s "${accession}/${accession}_16S_genes.fna" ]]; then
        rm "${accession}/${accession}_16S_genes.fna"
    fi
    """
}

// ===================================
// WORKFLOW
// ===================================

process package_data{ // this packages all three channels into a single channel of tuples to keep the data in order
    input:
    path fasta
    path gff
    val accession

    output:
    tuple path(fasta), path(gff), val(accession)

    exec:
    true 
}

workflow EXTRACT_16S_RRNA_GENES{
    take:
    data_dir

    main:
    // fastaChannel = data_dir
    //                 .flatMap {dir -> file("${dir}/**/*.fna")}
    // gffChannel = data_dir
    //                 .flatMap {dir -> file("${dir}/**/*.gff")}
    // accessionNames = fastaChannel
    //                     .flatMap {file -> file.parent.getName()}

    tupled_data = data_dir
                    .flatMap { dir ->
                        file("${dir}/**/*.fna")
                            .collect { fastaFile ->
                                def accession = fastaFile.parent.name
                                def gffFiles = file("${fastaFile.parent}/*.gff")
                                if (gffFiles && gffFiles.size() > 0) {
                                    tuple(fastaFile, gffFiles[0], accession)
                                } else {
                                    null
                                }
                            }
                            .findAll { it -> it != null }
                    }

    modified_gff_tuple = filter_gff3(tupled_data)
    reads_16S_fastas = extract_reads(modified_gff_tuple)
    reads_16S_gffs = modified_gff_tuple.map { tup -> tup[1] }

    // reads = get_16S_reads(fastaChannel, accessionNames)
    // reads_16S_fastas = reads.rrna_16S_fastas
    // reads_16S_gff3s = reads.rrna_16S_gff3s

    // modified_fasta_tuple = modify_fasta_files(fastaChannel, accessionNames)
    // reads_16S_gff3s_tuple = find_16S_read(modified_fasta_tuple)
    // reads_16S_fastas = extract_16S_reads(reads_16S_gff3s_tuple)

    // TODO: reformat fastas to follow ">accession:base-range" convention
    // all16Scopies = bedtools_call(gff2Files, fastaChannel)

    emit:
    // fastaFile
    reads_16S_fastas
    reads_16S_gffs
    // all16Scopies
}

workflow {
    EXTRACT_16S_RRNA_GENES("/dev/nul")
}