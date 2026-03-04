// ===================================
// Create V Region database
// ===================================

process get_v_regions{
    errorStrategy 'ignore' // this software that is used here is prone to issues, ones I can't replicate outside of nextflow,
                           // but it's not on every file so this will hopefully stop blocking the process
                           // It will need corrected in the future, probably by rerighting the logic using the same
                           // tools as the software but using strictly nextflow (don't write workflows in python, it's janky and hard to follow)
    input:
    val accession
    path accessions_16S_fasta
    path extract_regions

    output:
    path "${accession}_v_regions.fna"

    script:
    """
    python3 ${extract_regions} -i ${accessions_16S_fasta} -o ${accession}_v_regions.fna
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

workflow CREATE_RADLIB_VR{
    take:
    accession16SFiles

    main:
    // println("accessions 16s")
    // println(accession16SFiles.get(0).view())
    accessionNames = accession16SFiles
                        .flatMap {file -> file.parent.name}
    // println accessionNames.view()
    extract_v_regions_script = file("${projectDir}/scripts/extract_regions_16s/extract_regions")
    v_region_fastas_channel = get_v_regions(accessionNames, accession16SFiles, extract_v_regions_script)
    v_region_fastas = v_region_fastas_channel.collect()
    rad_vr = combine_v_region_fastas(v_region_fastas)

    emit:
    rad_vr
}