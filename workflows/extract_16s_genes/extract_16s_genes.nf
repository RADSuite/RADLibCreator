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
    awk -F'\t' '(\$3 == "rRNA" && \$9 ~ /16S/) || \$0 ~ /^#/' $gff2File > ${accession}/filtered_${accession}.gff 
    """
}

process extract_reads {
    input:
    tuple path(fasta), path(filteredGff3), val(accession)

    output:
    tuple path("${accession}/${accession}_16S_genes.fna"), 
          path(filteredGff3), 
          val(accession), optional: true // there may not be any documented 16S genes in this accession

    script:
    """
    mkdir ${accession} && touch "${accession}/${accession}_16S_genes.fna"
    bedtools getfasta -s -fi ${fasta} -bed ${filteredGff3} > "${accession}/${accession}_16S_genes.fna"
    if [[ ! -s "${accession}/${accession}_16S_genes.fna" ]]; then
        rm "${accession}/${accession}_16S_genes.fna"
    fi
    """
}

process format_headers {
    input:
    tuple path(fasta),
          path(filteredGff3), 
          val(accession)
    path accessions_db
    output:
        path("${accession}/${accession}_16S_genes.fna")

    script:
    """
    # Get Tax ID from gff file metadata
    taxId=\$(grep -oEm 1 "id=[0-9]+" $filteredGff3 | sed 's/id=//')

    # Get organism name from sqlite db
    organismName=\$(sqlite3 $accessions_db "SELECT name FROM names WHERE id = \$taxId")

    # Organize header data
    headerSuffix="|taxid=\$taxId organism=\\"\$organismName\\""
    declare -a geneAccession=( \$(grep -o "locus_tag=.*;" $filteredGff3 | sed -e 's/;.*//' -e 's/locus_tag=//') )

    # Update header
    mkdir -p ${accession}
    touch ${accession}/${accession}_16S_genes.fna
    currAccession=0
    while IFS= read -r line; do
        # Process the line here
        if [[ \$line = '>'* ]]; then
            line=">\${geneAccession[\$currAccession]}\$headerSuffix"
            ((++currAccession))
        fi
        echo "\$line" >> ${accession}/${accession}_16S_genes.fna
    done < $fasta
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
    accessions_db

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

    unformatted_reads_16S_fastas = filter_gff3(tupled_data)
                        | extract_reads

    // the ".first()" syntax converts the file channel into a value channel allowing it to be used for every input
    reads_16S_fastas = format_headers(unformatted_reads_16S_fastas, accessions_db.first())

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
    // all16Scopies
}

workflow {
    main:
    downloadedData = "${projectDir}/../../downloaded-data/data"
    accessions_db = "${projectDir}/../../downloaded-data/ncbi-accessions-data.db"
    if(!file(downloadedData).exists()){
        println "${downloadedData} not found"
    }
    if(!file(accessions_db).exists()){
        println "${downloadedData} not found"
    }
    EXTRACT_16S_RRNA_GENES(channel.of(file(downloadedData)), channel.of(file(accessions_db)))

    publish:
    fastas = EXTRACT_16S_RRNA_GENES.output.reads_16S_fastas
}

output {
    fastas{}
}