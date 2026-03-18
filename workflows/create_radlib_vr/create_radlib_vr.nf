// ===================================
// Create V Region database
// ===================================

process get_v_regions{
    errorStrategy 'ignore' // XXX: this software that is used here is prone to issues, ones I can't replicate outside of nextflow,
                           //      but it's not on every file so this will hopefully stop blocking the process
                           //      It will need corrected in the future, probably by rerighting the logic using the same
                           //      tools as the software but using strictly nextflow (don't write workflows in python, it's janky and hard to follow)
    input:
    val accession
    path accessions_16S_fasta
    path extract_regions

    output:
    path "${accession}_v_regions.fna"

    script:
    """
    modified_fasta=\$(mktemp)
    extracted_fasta=\$(mktemp)

    # This is needed because the python script used removes everything after the first white space
    sed 's/ /%/g' ${accessions_16S_fasta} > "\${modified_fasta}"
    python ${extract_regions} -i "\${modified_fasta}" -o "\${extracted_fasta}" 

    sed 's/%/ /g' "\${extracted_fasta}" |
    sed '/^>/!s/U/T/g' |
    sed 's/__V/ variable_region=/g' > "${accession}_v_regions.fna" 
    rm "\${modified_fasta}" "\${extracted_fasta}"
    """
}

process combine_v_region_fastas{
    input:
    path fastaFiles

    output:
    path "RADlib_vr.fa"

    script:
    """
    touch RADlib.fa
    find . -name "*.fna" -exec cat {} + >> RADlib_vr.fa
    """
}

// –––––––––––– Modified workflow/processes ––––––––––––
// HACK: this is a rewrite of the extract_regions python function using
//       updated software and covarient matrices

// TODO
process prepend_reference_sequence {
    script:
    """
    echo "Not implemented"
    """
}

// TODO
process align_sequences {
    script:
    """
    echo "Not implemented"
    """
}

// TODO
process find_v_regions_of_aligned_ref {
    """
    echo "Not implemented"
    """
}

// TODO
process extract_v_regions_of_queries {
    """
    echo "Not implemented"
    """
}

// –––––––––––––––––––––––––––––––––––––––––––––––––––––

workflow CREATE_RADLIB_VR{
    take:
    accession16SFiles

    main:
    accessionNames = accession16SFiles
                        .flatMap {file -> file.parent.name}
    
    extract_v_regions_script = file("${projectDir}/scripts/extract_regions_16s/extract_regions")
    if(!extract_v_regions_script.exists()){ // Needed for running workflow independently
        extract_v_regions_script = file("${projectDir}/../scripts/extract_regions_16s/extract_regions") 
    }

    v_region_fastas_channel = get_v_regions(accessionNames, accession16SFiles, extract_v_regions_script)
    rad_vr = v_region_fastas_channel.collectFile(name: "RADlibVR")

    emit:
    rad_vr
}

workflow {
    main:
    extracted16s = "${projectDir}/../../extracted-16S-reads"
    if(!file(extracted16s).exists()){
        println "${extracted16s} not found"
    }
    fasta_channel = channel.fromPath("$extracted16s/**/*.fna")
    CREATE_RADLIB_VR(fasta_channel)

    publish:
    radlibvr = CREATE_RADLIB_VR.output.rad_vr
}

output {
    radlibvr{}
}