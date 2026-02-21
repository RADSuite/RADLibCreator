.ONESHELL:
.PHONY: push_github_main push_github_dev test_apptainer test_conda test_docker commands

CONTAINER_DEF_DIR := container-files
CURR_BRANCH := $(shell git branch --show-current)
WORKFLOW := workflows/rad_workflow.nf

commands:
	@echo "**Available commands**"
	@echo "Builds:"
	@echo " - build_docker_image"
	@echo " - build_apptainer_image"
	@echo "Run:"
	@echo " - test_conda"
	@echo " - test_docker"
	@echo " - test_apptainer"
	@echo "Github (For maintainers only):"
	@echo " - push_github_main"
	@echo " - push_github_dev"

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
build_docker_image: ${CONTAINER_DEF_DIR}/Dockerfile
	docker build -t rad_nextflow_docker ${CONTAINER_DEF_DIR}

test_docker:
	nextflow run ${WORKFLOW} -profile test,docker

## Conda
test_conda: ${CONTAINER_DEF_DIR}/rad_nextflow_conda.yml ${WORKFLOW}
	nextflow run ${WORKFLOW} -profile test,conda

## Apptainer
build_apptainer_image: ${CONTAINER_DEF_DIR}/rad_apptainer.def ${WORKFLOW} 
	apptainer build ${CONTAINER_DEF_DIR}/rad_apptainer.sif $<

test_apptainer: ${CONTAINER_DEF_DIR}/rad_apptainer.sif ${WORKFLOW}
	nextflow run ${WORKFLOW} -profile test,apptainer