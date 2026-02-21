FROM nextflow/nextflow
FROM condaforge/mambaforge

WORKDIR /./

COPY . .

RUN apt-get update && apt-get install unzip

RUN conda env create -f rad_nextflow_conda.yml \
    && conda clean -afy

ENV PATH="/opt/conda/envs/RAD_nextflow_conda/bin:${PATH}"
