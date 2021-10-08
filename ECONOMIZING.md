# Money-Saving Setup

## Requirements

- Docker registry accessible from the web (can be public)
- Server to run the docker container

## Solution

### Docker registry

#### Introduction

A docker registry is a place that can distribute docker images. You can see it as a database that contains the image name (repository) and the list of associated tags.

To make things clear:

- _Docker Repository_: The name of the image, in our case _web-cc_
- _Docker Tag_: The tag of the image, used to identify different releases of the image (you can see it as a version number)
- _Docker Image_: The actual binary, it contains the instruction to start a docker container

Usually when you refer to a Docker image using the `docker` command, you use this syntax, eg:

```bash
docker run $REGISTRY_LOCATION/$REPOSITORY:$TAG
```

The `$REGISTRY_LOCATION` is the url where the docker registry is hosted, by default it points to `hub.docker.com`.
The `$TAG`, if not specified, is `latest`.

#### Dockerhub

Dockerhub (<https://hub.docker.com>) is the public registry where most of the official docker images are hosted. It is maintained by the Docker people. It allows you to create an account and use it to host your custom docker images.
When you create a repository on docker hub, it is always prefixed by `$USERNAME/`.
The free account allows you to store unlimited repositories which can contain unlimited tags, since for our use case we don't need privacy, it represent the cheapest and working solution.
The only limitation of the free account regards private repositories (only one) and `pull limits`: the max number of `docker pull` you can perform within a time frame.
For the free account the `pull limit` is set to 200/6h, and in our use case it is more than enough: I'm pretty sure we won't have to deploy 200 release a day on the production server.

_Trick: with anonymous account (without `docker login`) you have a `pull limit` of 100/6h. So to reach a maximum `pull limit` of 300/6h, you can always pull images with the anonymous user, and when the limit is reached, you can perform `docker login` to use your 200 pulls._

This setup will allow you to spend nothing, making it the best solution for us.

To setup a Dockerhub account, please refer to the `Publish the image on a registry` section of the `README.md` file.

### Server

A good compromise of price, simplicity and former know how can be found in Digital Ocean (DO), it offers severs at a reasonable price.
A DO server is called Droplet, and the smallest one comprehend:

- 1 vCPU
- 1GB of RAM
- 25GB of storage

For **5$/month**.

For the traffic of web-cc, I assume it will be more than enough.
Also, DO allows you to create Droplet with Docker already installed and configured, making it easy to setup our deployment.

To setup a DO Droplet with docker, please refer to the [official documentation](https://marketplace.digitalocean.com/apps/docker).

## Total Cost

Using this setup, the total cost for managing the infrastructure will be **5$/month**, that is the price of the Digital Ocean droplet.
