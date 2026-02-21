// ===================================
// Align 16S genes
// ===================================


process format_16S_fasta_files {
    input:
    path fastaFile
    val accession

    output:
    path "formatted-16S-hits/${accession}/16s_${accession}_formatted.fna", emit: formattedFastas
    path "formatted-16S-hits/", emit: root_dir

    script:
    """
    # Create a temp file to store intermediary steps
    touch temp
    
    mkdir -p formatted-16S-hits/${accession}
    sed 's/16S_rRNA::.*\\.[0-9]/${accession}/g' ${fastaFile} > temp
    # formatted-16S-hits/${accession}/16s_${accession}_formatted.fna
    copy_num=1
    while IFS= read -r line; do
        if [[ "\$line" == ">"* ]]; then
            line=\$(echo "\$line" | sed "s/:.*/.\$copy_num/")
            ((copy_num++))
        fi
        echo "\$line" >> formatted-16S-hits/${accession}/16s_${accession}_formatted.fna 
    done < temp

    rm -f temp
    """
}

process combine_fastas { //TODO: this portion will change when V region creation get's intigrated
    input:
    path fastaFiles

    output:
    path "RADlib.fa"

    script:
    """
    touch RADlib.fa
    find . -name "*.fna" -exec cat {} + >> RADlib.fa
    """
}

// ===================================
// Create RADlib 16S
// ===================================
workflow CREATE_RADLIB_16S{
    take:
    unformattedFastaFiles

    main: 
    accessionNames = unformattedFastaFiles
                        .flatMap {file -> file.parent.getName()}
    format_16S_fasta_files(unformattedFastaFiles, accessionNames)
    formattedFastas = format_16S_fasta_files.out.formattedFastas.collect()
    radlib = combine_fastas(formattedFastas) // FIXME: This process gets broken down into multiple channels when it should conbine all previous outputs

    emit:
    formattedFastas
    radlib
}