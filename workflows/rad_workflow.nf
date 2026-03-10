include { DOWNLOAD_DATA } from "./download_ncbi_data/download_ncbi_data.nf"
include { EXTRACT_16S_RRNA_GENES } from "./extract_16s_genes/extract_16s_genes.nf"
include { CREATE_RADLIB_16S } from "./create_radlib_16s/create_radlib_16s.nf"
include { CREATE_RADLIB_VR } from "./create_radlib_vr/create_radlib_vr.nf"

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
    EXTRACT_16S_RRNA_GENES(accessionsDir)
    
    // Create RADlib
    unformattedFastaFiles = EXTRACT_16S_RRNA_GENES.out.reads_16S_fastas
    CREATE_RADLIB_16S(unformattedFastaFiles)

    // Create RADlib_vr
    CREATE_RADLIB_VR(CREATE_RADLIB_16S.out.formatedFastaChannel)

    publish:
    downloadedData = DOWNLOAD_DATA.out.accessionGenes
    gff3s = EXTRACT_16S_RRNA_GENES.out.reads_16S_gffs
    fastas = EXTRACT_16S_RRNA_GENES.out.reads_16S_fastas
    formattedFastas = CREATE_RADLIB_16S.out.formattedFastasList
    radlib16s = CREATE_RADLIB_16S.out.radlib
    radlibvr = CREATE_RADLIB_VR.out.rad_vr
}

output {
    downloadedData{}
    gff3s{}
    fastas{}
    formattedFastas{}
    radlib16s{}
    radlibvr{}
}
