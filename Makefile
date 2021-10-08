SHELL := /bin/bash

IMAGE_NAME?=web-call.cc## Image name
IMAGE_TAG?=latest## Image tag
CONTAINER_NAME?=web-call.cc## Name of the container to run
CONTAINER_PORT?=8080## Port exposed by the container while running
DROPLET_USERNAME?=root## Username to access the droplet
DROPLET_IP?=164.90.211.183## IP of the droplet
DOCKERHUB_USERNAME?=tomelam## Username of the Docker Hub user
PLATFORMS?=linux/amd64,linux/arm64## Platforms to build in the multi-arch build

FULL_IMAGE_NAME=$(DOCKERHUB_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG)

help: ## Show this help
	@fgrep -h " ## " $(MAKEFILE_LIST) 	\
		| fgrep -v fgrep 				\
		| fgrep -v "?=" 					\
		| sed -e 's/\\$$//' 			\
		| sed -e 's/##//'
	@echo ""
	@echo VARIABLES:
	@fgrep -h "?=" $(MAKEFILE_LIST)	\
		| fgrep -v fgrep 			\
		| sed -e 's/\\$$//' 		\
		| sed -e 's/##/ ->/'

build: ## Build the docker image
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

run: ## Run the docker container
	docker run 					\
    --rm          				\
    --name $(CONTAINER_NAME)	\
    -d            				\
    -p $(CONTAINER_PORT):80    	\
    $(IMAGE_NAME):$(IMAGE_TAG)

stop: ## Stop the running container
	@if ! docker stop $(CONTAINER_NAME); then 	\
		echo $(CONTAINER_NAME) is not running.; \
	else 										\
		echo $(CONTAINER_NAME) stopped.; 		\
	fi;

restart: stop run ## Restart the container, useful if you built a new image

publish: build ## Build and publish the docker image on Docker Hub
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(FULL_IMAGE_NAME)
	docker push $(DOCKERHUB_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG)

publish_multi: ## Build a multi-arch image and publish it on Docker Hub
	docker buildx build 									\
		--platform $(PLATFORMS)      						\
		-t $(DOCKERHUB_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG)	\
		.                                       			\
		--push

deploy: ## Deploy the new image on the remote server
	ssh $(DROPLET_USERNAME)@$(DROPLET_IP) " 								\
		docker pull $(DOCKERHUB_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG);		\
		docker stop $(CONTAINER_NAME);										\
		echo Stopped container $(CONTAINER_NAME);							\
		docker rm $(CONTAINER_NAME); 										\
		echo Removed container $(CONTAINER_NAME);							\
		docker run --name $(CONTAINER_NAME) -p $(CONTAINER_PORT):80 -d $(FULL_IMAGE_NAME);	\
		echo Started container $(CONTAINER_NAME) with $(FULL_IMAGE_NAME);	\
	"

clean: ## Cleanup your machine from unused docker resources
	docker system prune -a

.PHONY: build
