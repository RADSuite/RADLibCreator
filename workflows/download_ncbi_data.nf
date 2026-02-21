// ===================================
// DOWNLOADING DATA FROM NCBI
// ===================================
process get_ncbi_genomes { // FIXME: need a more discriptive process title
    conda 'container-files/rad_nextflow_conda.yml'

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
    conda 'container-files/rad_nextflow_conda.yml'

    input:
    path accessions
    val numAccessions

    output:
    file "ncbi_dataset.zip"

    script:
    if (numAccessions > 0) { // Used for creating a smaller db for testing workflow
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
    conda 'container-files/rad_nextflow_conda.yml'
    
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