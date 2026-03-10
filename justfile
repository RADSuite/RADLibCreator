set shell := ["bash", "-cu"]

CONTAINER_DEF_DIR := "container-files"
WORKFLOW := "workflows/rad_workflow.nf"

push_github_main:
	#!/usr/bin/env bash
	branch=$(git branch --show-current)
	if [[ "$branch" != "main" ]]; then \
		echo "You are not currently on the main branch" \
		echo "Your branch is $branch" \
		exit 1 \
	fi
	git add .
	read -r -p "Set git message: " GIT_MESSAGE
	echo "$GIT_MESSAGE"
	git commit -m "$GIT_MESSAGE"
	git push -u origin main

push_github_dev: 
	#!/usr/bin/env bash
	branch=$(git branch --show-current)
	if [[ "$branch" != "dev" ]]; then 
	  echo "You are not currently on the dev branch"
	  echo "Your branch is $branch"
	  exit 1
	fi 
	git add . 
	read -r -p "Set git message: " GIT_MESSAGE 
	echo "$GIT_MESSAGE" 
	git commit -m "$GIT_MESSAGE" 
	git push -u origin dev 

build_docker_image:
	docker build --no-cache -t rad_nextflow_docker {{CONTAINER_DEF_DIR}}

test_docker:
	nextflow run {{WORKFLOW}} -profile test,docker

test_conda:
	nextflow run {{WORKFLOW}} -profile test,conda

build_apptainer_image:
	apptainer build {{CONTAINER_DEF_DIR}}/rad_apptainer.sif {{CONTAINER_DEF_DIR}}/rad_apptainer.def

test_apptainer:
	nextflow run {{WORKFLOW}} -profile test,apptainer