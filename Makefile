#SHELL := /bin/bash

# Image name
IMAGE          ?= web-call.cc
# Image tag
TAG            ?= latest
# Container name
CONT           ?= web-call.cc
# Container port
CONT_PORT      ?= 8080
# Docker Hub username
DHUB_UNAME     ?= tomelam
# Docker platforms
PLATFORMS      ?= linux/amd64,linux/arm64
# Digital Ocean droplet username
DROPLET_UNAME  ?= root
# Internet-exposed IP address of the Digital Ocean droplet
DROPLET_IP     ?= 164.90.211.183

help:
	@echo "Please choose one of the following targets:"
	@echo "build, run, stop, restart, publish, publish_multi, deploy,"
	@echo "list, rm, rmi, clean"

build:
	docker build -t $(IMAGE):$(TAG) .

run:
	docker run --rm --name $(CONT) -d -p $(CONT_PORT):80 $(IMAGE):$(TAG)

stop:
	@if ! docker stop $(CONT); then \
		echo $(CONT) is not running.; \
	else \
		echo $(CONT) stopped.; \
	fi;

restart: stop run

publish:
	docker tag $(IMAGE):$(TAG) $(DHUB_UNAME)/$(IMAGE):$(TAG)
	docker push $(DHUB_UNAME)/$(IMAGE):$(TAG)

publish_multi:
	docker buildx build \
	    --platform $(PLATFORMS) \
	    -t $(DHUB_UNAME)/$(IMAGE):$(TAG) . --push

deploy:
	ssh $(DROPLET_UNAME)@$(DROPLET_IP) " \
	  docker pull $(DHUB_UNAME)/$(IMAGE):$(TAG); \
	  docker stop $(CONT); \
	  echo Stopped container $(CONT); \
	  docker rm $(CONT); \
	  echo Removed container $(CONT); \
	  docker run --name $(CONT) -p $(CONT_PORT):80 \
	    -d $(DHUB_UNAME)/$(IMAGE):$(TAG); \
	  echo Started container $(CONT) with $(DHUB_UNAME)/$(IMAGE):$(TAG); \
	"

list:
	docker images
	@echo
	docker ps

rm:
	docker rm $(CONT)

rmi:
	docker rmi $(IMAGE)

clean:
	echo docker system prune -a
