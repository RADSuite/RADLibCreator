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
    wget -c https://ftp.ncbi.nlm.nih.gov/genomes/refseq/assembly_summary_refseq.txt
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
process barrnap_call {
    input:
    path filePath

    output:
    path "the16S.gff3"

    script:
    """
    barrnap --kingdom bac ${filePath} | grep 16S > the16S.gff3
    """

}

process bedtools_call {
    input:
    path gff2File
    path fastaFile

    output:
    path "16s_rrna_genes.fa"

    script:
    """
    bedtools getfasta -fi $fastaFile -bed $gff2File > 16s_rrna_genes.fa 
    """

}



// ===================================
// Align 16S genes
// ===================================

process combine_fastas {
    input:
    path ncbi_data

    output:
    path "combined_NCBI_16S_reads.fa"

    script:
    """
    # for dir in ncbi_data_dir
    # select reads=16S_*.fa 
    # retitle 16S reads, add period and found order to end of accession
    # cat reads >> combined_NCBI_16S_reads.fa (RADlib?)
    """
}

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
    println accessionGenes

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
    println data_dir // Temp to avoid warnings
    fastaFiles = file("$data_dir/**.fna")
    pathChannel = channel.fromPath(fastaFiles)
    gff2Files = barrnap_call(pathChannel)
    all16Scopies = bedtools_call(gff2Files, fastaFiles)

    emit:
    // fastaFile
    gff2Files
    all16Scopies
}

// ===================================
// Align 16S genes
// ===================================
workflow ALIGN_16S_GENES{
    // take:
    // data

    main:
    println("TEMP!")
}


workflow{
    main:
    // Downloading data from NCBI
    DOWNLOAD_DATA()

    // TODO: connect the previous and next steps to find all 16S reads
    // Extract 16S genes from whole genome

    // Channel.fromPath("data/*/16S_reads_*.fa") gets a channel of all dirs and 16S fasta reads
    EXTRACT_16S_RRNA_GENES(DOWNLOAD_DATA.out.accessionGenes) // TODO: a channel should be involved here to speed up processing genomes

    publish:
    downloadedData = DOWNLOAD_DATA.out.accessionGenes
    gffs = EXTRACT_16S_RRNA_GENES.out.gff2File
    allReads = EXTRACT_16S_RRNA_GENES.out.all16Scopies
}

output {
    downloadedData{}
    gffs{}
    allReads{}
}
