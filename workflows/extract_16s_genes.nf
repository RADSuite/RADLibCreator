// ===================================
// EXTRACT 16S GENES FROM WHOLE GENOME
// ===================================

// process modify_fasta_files {
//     /*
//     TODO: This process will convert all ambiguous nucleotides to 'N'
//           barrnap's use of nhmmer doesn't specify the language properly so nhmmer 
//           cannot detect the alphabet like it should. Converting all ambiguous 
//           nucleotides seems to fix this issue. barrnap exports its finings in 
//           a gff3 format that can be passed into bedtools getfasta with the unmodified
//           fasta file to get the correct 16S region
//     */
//     input:
//     path originalFasta
//     val accession

//     output:
//     tuple path("${accession}/modified_${accession}.fna"), path(originalFasta), val(accession)

//     script:
//     """
//     mkdir ${accession}
//     touch ${accession}/modified_${accession}.fna
//     sed '/^[>]/! s/[^A|T|G|C|>]/N/g' $originalFasta > ${accession}/modified_${accession}.fna
//     """
// }

// process find_16S_read {
//     /*
//     TODO: This process takes in the modified fasta file from modify_fasta_files
//           and passes it into barrnap to get the gff3 file, filtered with only the 
//           16S hits
//     */
//     input: 
//     tuple path(modifiedFasta), path(originalFasta), val(accession)

//     output:
//     tuple path("${accession}/16S_hits_${accession}.gff3"), path(originalFasta), val(accession)

// // FIXME: if gff doesn't find a 16S read, grep fails and breaks
//     script:
//     """
//     set -o pipefail
//     mkdir ${accession}
//     touch ${accession}/16S_hits_${accession}.gff3 
//     barrnap --quiet ${modifiedFasta} | grep '16S' > ${accession}/16S_hits_${accession}.gff3 || echo "No 16S found"
//     """
// }

// process extract_16S_reads {
//     /*
//     TODO: This process takes in the original fasta file and the generated gff3 file
//           and extracts the 16S hits using bedtools getfasta
//     */
//     input:
//     tuple path(hits16Sgff3), path(originalFasta), val(accession)

//     output:
//     path "16S-hits/${accession}/16S_${accession}.fna", emit: rrna_16S_fastas, optional: true

//     script:
//     """
//     if [[ -s ${hits16Sgff3} ]]; then
//         mkdir 16S-hits
//         mkdir 16S-hits/${accession}
//         touch 16S-hits/${accession}/16S_${accession}.fna 
//         bedtools getfasta -fi ${originalFasta} -bed ${hits16Sgff3} > "16S-hits/${accession}/16S_${accession}.fna" 
//     fi
//     """
// }

// process get_16S_reads {
//     conda 'container-files/rad_nextflow_conda.yml'
// /*
// FIXME: REFACTOR WITH USING THE ABOVE PROCESSES
// barrnap currently has an issue with hmmer where it cannot automatically detect the correct alphabet
// This can be fixed, hopefully, by converting all ambiguous nucleotides to N
// This alteration will need to be reversed after the 16S regions are isolated
// */
//     input:
//     path filePath
//     val accessionName

//     output:
//     path "16S-hits/${accessionName}/gff3_${accessionName}.gff3", emit: rrna_16S_gff3s
//     path "16S-hits/${accessionName}/16S_${accessionName}.fna", emit: rrna_16S_fastas, optional: true

//     script:
//     """
//     mkdir -p 16S-hits/${accessionName} 
//     output_file="16S-hits/${accessionName}/16S_${accessionName}.fna"
//     touch \$output_file
//     barrnap --kingdom bac ${filePath} -outseq 16S-hits/${accessionName}/temp_16S_${accessionName}.fna \
//         > 16S-hits/${accessionName}/gff3_${accessionName}.gff3 
//     seqkit grep -nr -p "16S" 16S-hits/${accessionName}/temp_16S_${accessionName}.fna > 16S-hits/${accessionName}/16S_${accessionName}.fna
//     if [[ ! -s 16S-hits/${accessionName}/16S_${accessionName}.fna ]]; then
//         echo "No 16S genes were found in ${accessionName}. Removing file"
//         rm 16S-hits/${accessionName}/16S_${accessionName}.fna
//     fi
//     """

// }

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
    bedtools getfasta -fi ${fasta} -bed ${filteredGff3} > "${accession}/${accession}_16S_genes.fna"
    if [[ ! -s "${accession}/${accession}_16S_genes.fna" ]]; then
        rm "${accession}/${accession}_16S_genes.fna"
    fi
    """
}

// process actually_work {
// // TODO: use the downloaded gff file
// // use awk to filter column $3 == "rRNA" and $9 ~ /16S/
// // use filtered gff3 and bedtools to extract 16S from fasta files
//     script:
//     """
//     echo Hi...
//     """
// }

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