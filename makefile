.ONESHELL:
.PHONY: push_github_main push_github_dev test_apptainer test_conda test_docker

CURR_BRANCH := $(shell git branch --show-current)
WORKFLOW := rad_workflow.nf

## Github
push_github_main:
ifneq '${CURR_BRANCH}' 'main'
	echo "You are not currently on the main branch"
	echo "Your branch is ${CURR_BRANCH}"
else 
	git add .
	@read -p "Set git message: " GIT_MESSAGE; \
	echo $${GIT_MESSAGE}; \
	git commit -m "$${GIT_MESSAGE}"; \
	git push -u origin main 
endif

push_github_dev:
ifneq '${CURR_BRANCH}' 'dev'
	echo "You are not currently on the main branch"
	echo "Your branch is ${CURR_BRANCH}"
else 
	git add .
	@read -p "Set git message: " GIT_MESSAGE; \
	echo $${GIT_MESSAGE}; \
	git commit -m "$${GIT_MESSAGE}"; \
	git push -u origin dev 
endif


## Docker
build_docker_image: Dockerfile
	docker build -t rad_nextflow_docker .

test_docker:
	nextflow run ${WORKFLOW} -profile test,docker

## Conda
test_conda: rad_nextflow_conda.yml
	nextflow run ${WORKFLOW} -profile test,conda

## Apptainer
build_apptainer_image: rad_apptainer.def 
	apptainer build rad_apptainer.sif $<

test_apptainer: rad_apptainer.sif
	nextflow run ${WORKFLOW} -profile test,apptainer