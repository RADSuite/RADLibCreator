// ===================================
// Create V Region database
// ===================================

process align_on_e_coli{
    input:
    path e_coli_seq
    path fasta_file 
    val accession

    output:
    path "${accession}_aligned_on_e_coli.sto"
    
    script:
    '''
    echo This is a place holder
    '''
}

process select_v_region_indices{
    input:
    path aligned_sto
    path find_index_script

    output:
    stdout emit: V_Regions

    script:
    '''
    ./${find_index_script} ${aligned_sto}
    '''
}

workflow GET_V_REGIONS{

}