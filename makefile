.ONESHELL:
.PHONY: push_github_main push_github_dev

CURR_BRANCH := $(shell git branch --show-current)

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
	echo Command not set
# 	exit 1
# 	git add .
# 	read GIT_MESSAGE
# 	git commit -m dev

# read_input:
# 	# Prompt the user for input and store it in a bash variable 'CONTINUE'
# 	read -r -p "Type anything but Y or y to exit. [y/N]: " CONTINUE
# 	# Check the value of the bash variable
# 	if [[ "$$CONTINUE" != "y" && "$$CONTINUE" != "Y" ]]; then
# 		echo "Exiting.";
# 		exit 1;
# 	fi
# 	echo "Continuing with the task..."
# 	# Add more commands here

build_docker_image: Dockerfile
	docker build -t rad_nextflow_docker .

test_docker:
	nextflow run rad_workflow.nf -profile test,docker

test_conda:
	nextflow run rad_workflow.nf -profile test,conda	