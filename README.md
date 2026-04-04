# RADlib create pipeling

This nextflow pipeline is designed to generate the RADlib databases used in
the RADlib suite.

## Using this pipeling

### Clone

Currently, this pipeline is only available on GitHub.\
To clone this repository, run

```{shell}
git clone --recurse-submodules https://github.com/RADSuite/RADLibCreator.git
```

### Nextflow

This workflow is written for Nextflow 25. If you have nextflow installed, make
sure it is at least version 25. If you do not have nextflow installed, you can
see if your system meets the requirments to run Nextflow [here](https://www.nextflow.io/docs/latest/install.html#requirements)
To download Nextflow, you can follow the instructions [here](https://www.nextflow.io/docs/latest/install.html#conda).
Nextflow can be installed without Conda but it is recommended.

## Containers

It is recommended that you use a container such as Docker or Singularity/Apptainer
to run this workflow. It is possible to create a Conda environment and use that 
to run the workflow but it is prone to incompatability issues

### Docker

Start by downloading Docker. Docker provides instructions on how to download the
version of Docker for your OS and archetecture [here](https://docs.docker.com/engine/install/).
It is recommended to download Docker desktop if you are not use to running docker
in the terminal.

Once Docker is installed, you can build the RADlib Docker container by running

```{shell}
docker build -t radlib:latest container-files
```

This docker container is 4.22GB so make sure you have enough available storage.

### Apptainer

Docker is not available on most HPC so an Apptainer/Singularity .def file is also
available in the container-files directory. You can run this command to create the 
Apptainer image.

```{shell}
apptainer build my_image.sif
```

### Conda

It is not recommended to just use Conda but if you do not have access to container
programms a conda enviroment can be created. A Conda yaml file is provided in the 
container-files directory to create an environment.

```{shell}
conda env create -f container-files/rad_nextflow_conda.yml
```

## Running to workflow

This workflow creates a large number of files so please be cautious of the limits
your device has: memory, storage, and any file number limits.

To try the workflow on a local device, you can run
```{shell}
nextflow run workflows/rad_workflow.nf -profile test,docker
```

To run the full workflow, run

```{shell}
nextflow run workflows/rad_workflow.nf -profile docker
```

> If you are not using Docker, replace the `docker` parameter with `apptainer` or `conda`.

### Trouble shooting

If you run into issues with the number of files created during exicutions, each subworkflow
can be run independently. Follow these steps to run each step.

```{shell}
nextflow run workflows/download_ncbi_genes/download_ncbi_data.nf -profile docker
```

```{shell}
nextflow run workflows/extract_16s_genes/extract_16s_genes.nf -profile docker
```

```{shell}
nextflow run workflows/create_radlib_16s/create_radlib_16s.nf -profile docker
```

```{shell}
nextflow run workflows/create_radlib_vr/create_radlib_vr.nf -profile docker
```

## Future

In future itterations of the RADlibCreate pipeling, we hope to remove the dependency
on annotated wgs from ncbi so users can create RADlibs with their own data.

We also hope to publish this workflow to nf-core and the Docker image to Dockerhub.