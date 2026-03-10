FROM nextflow/nextflow
FROM condaforge/mambaforge

WORKDIR /./

COPY . .

RUN apt-get update && apt-get install unzip

RUN pwd

RUN conda env create -f rad_nextflow_conda.yml 

ENV PATH="/opt/conda/envs/RAD_nextflow_conda/bin:${PATH}"
