/*
 * Config file found in project directory as `nextflow.config`
 * Parameters are specified in the config file
 * https://www.nextflow.io/docs/latest/config.html#configuration-files
*/

// TODO: This requires specific tools be available so it should require a conda env or docker or something...

// ===================================
// DOWNLOADING DATA FROM NCBI
// ===================================
process get_ncbi_genomes { // FIXME: need a more discriptive process title
    output:
    path "assembly_summary_refseq.txt"

    script:
    """
    wget -c -O assembly_summary_refseq.txt https://ftp.ncbi.nlm.nih.gov/genomes/refseq/assembly_summary_refseq.txt
    """
}

process filter_bac_arch_accessions {
    input:
    path ncbiRefSeq
    path filterScript

    output:
    path "ncbi_accessions.tsv"

    script:
    """
    awk -f $filterScript $ncbiRefSeq > ncbi_accessions.tsv
    """
}

process get_accession_wgs_dehydrated {
    conda 'rad_nextflow_conda.yml'

    input:
    path accessions
    val numAccessions

    output:
    file "ncbi_dataset.zip"

    script:
    if (numAccessions > 0) {
        """
        datasets download genome accession \
            --dehydrated \
            --inputfile <(head -n $numAccessions $accessions) \
            --include genome \
            --filename ncbi_dataset.zip
        """
    } else { // Full download. Can take over 5 hours to complete depending on number of accessions to download
        """
        datasets download genome accession \
            --dehydrated \
            --inputfile $accessions \
            --include genome \
            --filename ncbi_dataset.zip
        """
    }
}

process rehydrate_genomes {
    conda 'rad_nextflow_conda.yml'
    
    input:
    path genomeDir

    output:
    path "data/"

    script:
    """
    mkdir data
    unzip $genomeDir -d ncbi_data
    datasets rehydrate --directory ncbi_data
    mv ncbi_data/ncbi_dataset/data .
    """
}

// ===================================
// EXTRACT 16S GENES FROM WHOLE GENOME
// ===================================
process get_16S_reads {
    conda 'rad_nextflow_conda.yml'

    input:
    path filePath
    val accessionName

    output:
    path "16S-hits/${accessionName}/gff3_${accessionName}.gff3", emit: rrna_16S_gff3s
    path "16S-hits/${accessionName}/16S_${accessionName}.fna", emit: rrna_16S_fastas

    script:
    """
    mkdir -p 16S-hits/${accessionName} 
    output_file="16S-hits/${accessionName}/16S_${accessionName}.fna"
    touch \$output_file
    barrnap --kingdom bac ${filePath} -outseq 16S-hits/${accessionName}/temp_16S_${accessionName}.fna \
        > 16S-hits/${accessionName}/gff3_${accessionName}.gff3
    seqkit grep -nr -p "16S" 16S-hits/${accessionName}/temp_16S_${accessionName}.fna > 16S-hits/${accessionName}/16S_${accessionName}.fna
    """

}


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
    TEMPFILE=\$(mktemp)
    mkdir -p formatted-16S-hits/${accession}
    sed 's/16S_rRNA::.*\\.[0-9]/${accession}/g' ${fastaFile} > \$TEMPFILE
    # formatted-16S-hits/${accession}/16s_${accession}_formatted.fna
    copy_num=1
    while IFS= read -r line; do
        if [[ "\$line" == ">"* ]]; then
            line=\$(echo "\$line" | sed "s/:.*/.\$copy_num/")
            ((copy_num++))
        fi
        echo "\$line" >> formatted-16S-hits/${accession}/16s_${accession}_formatted.fna 
    done < "\$TEMPFILE"
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

// process create RADlibV*

// process filter accessions

process filter_distinct_16S_reads {
    input:
    path combined_16S_fasta

    output:
    path "aligned_NCBI_16S_regions.fa"

    script:
    """
    # python script
    # reads in all 16S reads
    # creates a dict with reads as keys and value is tuple of accession and read
    # appends accessions that have the same 16S reads
    # outputs fastas titled ">read_num [accessions=...]\n16S gene"
    """

}


// ===================================
// WORKFLOW
// ===================================

workflow DOWNLOAD_DATA{
    main:
    def accessionLimit
    if (params.containsKey('limitAccession')){
        accessionLimit = params.limitAccession
    } else {
        accessionLimit = -1
    }

    ncbiRefSeq = get_ncbi_genomes()
    filterScript = file("${projectDir}/scripts/filter_assembly.awk")
    accessions = filter_bac_arch_accessions(ncbiRefSeq, filterScript)
    zippedWGS = get_accession_wgs_dehydrated(accessions, accessionLimit)
    accessionGenes = rehydrate_genomes(zippedWGS) 
    accessionGenes.view()

    emit:
    ncbiRefSeq
    accessions
    zippedWGS
    accessionGenes
}


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

// ===================================
// Create RADlib
// ===================================
workflow CREATE_RADLIB{
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


workflow{
    main:
    // Downloading data from NCBI
    DOWNLOAD_DATA()

    // Get 16S reads
    accessionsDir = DOWNLOAD_DATA.out.accessionGenes
    EXTRACT_16S_RRNA_GENES(accessionsDir) // TODO: a channel should be involved here to speed up processing genomes
    
    // Create RADlib
    unformattedFastaFiles = EXTRACT_16S_RRNA_GENES.out.reads_16S_fastas
    CREATE_RADLIB(unformattedFastaFiles)


    publish:
    downloadedData = DOWNLOAD_DATA.out.accessionGenes
    gff3s = EXTRACT_16S_RRNA_GENES.out.reads_16S_gff3s
    fastas = EXTRACT_16S_RRNA_GENES.out.reads_16S_fastas
    formattedFastas = CREATE_RADLIB.out.formattedFastas
    radlib = CREATE_RADLIB.out.radlib
}

output {
    downloadedData{}
    gff3s{}
    fastas{}
    formattedFastas{}
    radlib{}
}
