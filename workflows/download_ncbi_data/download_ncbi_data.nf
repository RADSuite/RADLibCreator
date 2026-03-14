// ===================================
// DOWNLOADING DATA FROM NCBI
// ===================================
process get_ncbi_genomes { // FIXME: need a more discriptive process title
    label 'REQUIRES_INTERNET'
    conda 'container-files/rad_nextflow_conda.yml'

    input:
    env 'NCBI_API_KEY'

    output:
    // path "assembly_summary_refseq.txt"
    path "refseq_taxa_summary.json"

    script:
    """
    USE_KEY=""
    if [ -n "\$NCBI_API_KEY" ]; then
        USE_KEY="--api-key \$NCBI_API_KEY"
    fi
    # Taxanomic IDs: Bacteria, 2; Archaea, 2157 (Needed because Bacteria is associated with multiple taxa labels)
    datasets summary genome taxon 2,2157 \
        --assembly-source RefSeq \
        --as-json-lines \
        \$USE_KEY \
        --reference > refseq_taxa_summary.json 
    """
}

// process filter_bac_arch_accessions {
//     input:
//     path ncbiRefSeq
//     path filterScript

//     output:
//     path "ncbi_accessions.tsv"

//     script: // Convert this into an sql query. ncbi_accessions need to be in sqlite to export to metascope
//     """
//     awk -f $filterScript $ncbiRefSeq > ncbi_accessions.tsv
//     """
// }

process create_sqlite3_db {
    input:
    path json_data
    path sql_script

    output:
    path "ncbi-accessions-data.db"

    script:
    """
    # Reformate data from json to tsv
    touch temp.tsv
    dataformat tsv genome --inputfile $json_data > temp.tsv
    # Load data into sqlite db and create extra tables
    sqlite3 ncbi-accessions-data.db < $sql_script
    rm temp.tsv
    """
}

process get_accession_wgs_dehydrated {
    label 'REQUIRES_INTERNET'
    conda 'container-files/rad_nextflow_conda.yml'

    input:
    path accessions_db
    val numAccessions

    output:
    file "ncbi_dataset.zip"

    script:
    if (numAccessions > 0) { // Used for creating a smaller db for testing workflow
        """
        accessions=\$(sqlite3 $accessions_db 'SELECT accession FROM accessionTaxa LIMIT $numAccessions;')
        datasets download genome accession \
            --dehydrated \
            --inputfile <(echo "\$accessions") \
            --include genome,gff3 \
            --filename ncbi_dataset.zip
        """
    } else { // Full download. Can take over 5 hours to complete depending on number of accessions to download
        """
        accessions=\$(sqlite3 $accessions_db 'SELECT accession FROM accessionTaxa LIMIT $numAccessions;')
        datasets download genome accession \
            --dehydrated \
            --inputfile <(echo "\$accessions") \
            --include genome,gff3 \
            --filename ncbi_dataset.zip
        """
    }
}

process rehydrate_genomes {
    label 'REQUIRES_INTERNET'
    conda 'container-files/rad_nextflow_conda.yml'
    
    input:
    path genomeDir
    env 'NCBI_API_KEY'

    output:
    path "data/"

    script:
    """
    mkdir data
    unzip $genomeDir -d ncbi_data
    USE_KEY=""
    if [ -n "\$NCBI_API_KEY" ]; then
        USE_KEY="--api-key \$NCBI_API_KEY"
    fi
    datasets rehydrate \$USE_KEY --directory "ncbi_data"
    mv "ncbi_data/ncbi_dataset/data" .
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

    json_result = get_ncbi_genomes(params.NCBI_API_KEY)

    // SQL script used to format SQLite database when it is created
    sql_scipt = file("${projectDir}/scripts/load_refseq_db.sql")
    if(!sql_scipt.exists()){ // Needed for running workflow independently
        sql_scipt = file("${projectDir}/../scripts/load_refseq_db.sql") 
    }

    refseq_db = create_sqlite3_db(json_result, sql_scipt)
    zippedWGS = get_accession_wgs_dehydrated(refseq_db, accessionLimit)
    accessionGenes = rehydrate_genomes(zippedWGS, params.NCBI_API_KEY ?: "") 
    accessionGenes.view()

    emit:
    refseq_db
    zippedWGS
    accessionGenes
}

workflow {
    main:
    DOWNLOAD_DATA()

    publish:
    refseq_db = DOWNLOAD_DATA.output.refseq_db
    zippedWGS = DOWNLOAD_DATA.output.zippedWGS
    accessionGenes = DOWNLOAD_DATA.output.accessionGenes
}

output{
    refseq_db{} 
    zippedWGS{}
    accessionGenes{}
}
