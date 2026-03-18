# RADlib Create

RADlib Create is the workflow for regenerating RADlib files. It can also be 
used to create custome RADlib libraries for research specific requirments.

RADlib are 16S rRNA libraries/databases used in microbiome research. Currently,
RADlib is specialized for Human microbiome data.

Clone repo:
```{shell}
git clone --recurse-submodules https://github.com/RADSuite/RADLibCreator.git 
```

You can optionally add an NCBI API key to speed up download time by creating
one on NBNI and then adding a nextflow secret
```{shell}
nextflow sectret set NCBI_API_KEY <your key>
```

## Profiles
There are multiple profiles to add to change exicution
- `docker`
    - Run using a docker container
- `apptainer`
    - Run using an apptainer container (recommended for hpc)
- `conda`
    - Create a conda env before execution with necissary packages
- `autoClean`
    - Use nf-boost's auto cleaning functionality (in development)


## FUTURE 

Add process to download ncbi wgs accession2taxa files https://github.com/DerrickWood/kraken2/wiki/Manual#custom-databases

Add workflow create kraken2 database

Add workflow to create MetaScope database
