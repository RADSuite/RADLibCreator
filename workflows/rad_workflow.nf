include { DOWNLOAD_DATA } from "./download_ncbi_data.nf"
include { EXTRACT_16S_RRNA_GENES } from "./extract_16s_genes.nf"
include { CREATE_RADLIB_16S } from "./create_radlib_16s.nf"

// TODO
// ===================================
// Create RADlib V
// ===================================

// TODO
// ===================================
// Create RADlib Exports
// ===================================


workflow{
    main:
    // Downloading data from NCBI
    DOWNLOAD_DATA()

    // Get 16S reads
    accessionsDir = DOWNLOAD_DATA.out.accessionGenes
    EXTRACT_16S_RRNA_GENES(accessionsDir) // TODO: a channel should be involved here to speed up processing genomes
    
    // Create RADlib
    unformattedFastaFiles = EXTRACT_16S_RRNA_GENES.out.reads_16S_fastas
    CREATE_RADLIB_16S(unformattedFastaFiles)


    publish:
    downloadedData = DOWNLOAD_DATA.out.accessionGenes
    gff3s = EXTRACT_16S_RRNA_GENES.out.reads_16S_gff3s
    fastas = EXTRACT_16S_RRNA_GENES.out.reads_16S_fastas
    formattedFastas = CREATE_RADLIB_16S.out.formattedFastas
    radlib = CREATE_RADLIB_16S.out.radlib
}

output {
    downloadedData{}
    gff3s{}
    fastas{}
    formattedFastas{}
    radlib{}
}
