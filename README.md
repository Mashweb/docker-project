# Quick How-to on Building, Publishing, and Deploying a Docker Project

This how-to is a quick guide to setting up and maintaining Docker images,
containers, and deployments on a VPS like Digital Ocean.
The normal sequence is: build locally, run locally, publish, and deploy. 

_NB: This README documents commands using lines up to 80 characters long.
Please ensure that your viewing window does not truncate any of those lines._

## Build and use the image locally

_This section assumes you have Docker installed and running on your machine.
(See <https://docs.docker.com/get-docker/>)._


```bash
# Build the Docker image.
docker build \
    -t web-call.cc:latest \ # Name your image to access it later
                          \ # locally.
    .

# List the Docker images present on your computer. You should
# see "web-call.cc" there.
docker images

# Run your container.
docker run             \
    --rm               \ # Remove the container when stopped.
                       \ # This helps to save space and make the
                       \ # command idempotent.
    --name web-call.cc \ # Name of container so you can access it
                       \ # later on.
    -d                 \ # Run the container in the background
                       \ # (optional).
    -p 8080:80         \ # Map port 80 of the container to port
                       \ # 8080 of your machine. If the 8080 port
                       \ # is busy, please use another one.
    web-call.cc:latest

# List all the running containers. You should see the
# "web-call.cc" container there.
docker ps
# List all containers, both running and stopped.
docker ps -a

# Check the logs of your container (in this case httpd logs).
docker logs -f web-call.cc

# You can now access the website at localhost:8080 .

# Access your container.
docker exec \
    -it \ # Attach the tty to allow interactive operations
    web-call.cc \ # name of your container
    sh # The executable to run

# Stop and remove the container.
docker stop web-call.cc

# The website goes offline when the container is stopped.

```

## Publish the image on a registry

Unfortunately it is not possible to just copy a Docker image to a remote location; you need an intermediary called
a registry. If you have the image locally, you can easily push it to a registry and then pull it from the remote location.
For the sake of simplicity, we can use the Docker Hub registry instead of running our own registry, which allows us to create one
private repository with Docker Hub's free account.

### Create Docker Hub account

1. Go to <https://hub.docker.com/>;
2. Signup using the form;
3. Confirm the email;
4. Click on your name on the top right of the page -> Account Settings;
5. Click on "Security" -> Access Token -> New access token;
6. Fill in the data and click "Generate";
7. Copy the token and save it somewhere private and secure.

### Create a new image repository

1. Go to <https://hub.docker.com/>;
2. Login to your account;
3. Click "Create Repository";
4. Type "web-call.cc" as the name and "web-call.cc app" as the Description;
5. Flag it as "Private";
6. Click "Create"

### Push the local image to Docker Hub

```bash
DOCKERHUB_USERNAME="The name you registered with"
ACCESS_TOKEN="The token saved before"

# Login into Docker Hub. It is required to have permissions to
# publish the image.
docker login -u $DOCKERHUB_USERNAME -p $ACCESS_TOKEN

# This login might print "WARNING! Using --password via the CLI
# is insecure. Use --password-stdin."

# Tag the image by specifying the correct repository and
# a useful tag (the hub.docker.com prefix is implicit).
docker tag web-call.cc $DOCKERHUB_USERNAME/web-call.cc:latest

# Push the image to Docker Hub.
docker push $DOCKERHUB_USERNAME/web-call.cc:latest
```

### Create and push a multi-arch image to Docker Hub

This section instructs you to build a multi-architecture image and push it on Docker Hub.
This is particularly useful when you perform your work a machine with a different architecture
than `amd64` (eg: M1 ([Apple Silicon](https://docs.docker.com/desktop/mac/apple-silicon/)) Macs
use the ARM architecture): since most of the servers in the cloud market are shipped with the
`amd64` architecture, we need to ensure that the image we are creating is compatible with them.
To do so we need to create a multi-architecture image that supports the `amd64` architecture, the
preferred tools is `docker buildx`, for more information regarding `buildx`, please refer to the
following resources:

- <https://docs.docker.com/buildx/working-with-buildx/>
- <https://www.docker.com/blog/multi-arch-images/>
- <https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/>
- <https://docs.docker.com/desktop/multi-arch/>
- <https://docs.docker.com/desktop/mac/apple-silicon/>

_Please note that `buildx` is automatically shipped with Docker versions >= 19, so you don't need to
perform any additional installation steps._

#### Setup buildx to use create multi-arch builds

```bash
# Create the multi-arch builder.
docker buildx create --use --name multi-arch-builder

# Get information from the current builder, you will see that
# currently, there are no platforms available and the builder
# is inactive.
docker buildx inspect

# Activate the builder and setup the platforms by appending the
# "--bootstrap" flag. It will pull the
# "moby/buildkit:buildx-stable-1" and start a container with
# it. The container will be used to perform the multi-arch build.
docker buildx inspect --bootstrap
```

#### Create and push the image

```bash
DOCKERHUB_USERNAME="The name you registred with"
ACCESS_TOKEN="The token saved before"

# Login into Docker Hub. It is required to have permissions to
# publish the image.
docker login -u $DOCKERHUB_USERNAME -p $ACCESS_TOKEN

# This login might print "WARNING! Using --password via the CLI
# is insecure. Use --password-stdin."

# Perform the multi-arch build, the --push flag will automatically
# push the image to Docker Hub.
docker buildx build \
    --platform linux/amd64,linux/arm64      \
    -t $DOCKERHUB_USERNAME/web-call.cc:latest    \
    .                                       \
    --push

# Check that the image is shipped with multiple architectures
docker buildx imagetools inspect $DOCKERHUB_USERNAME/web-call.cc:latest
```

Is it also possible to check that the image supports multiple architecture
from the Docker Hub web page:

1. Go to <https://hub.docker.com/>;
2. Login to your account;
3. Click on $DOCKERHUB_USERNAME/web-call.cc;
4. Click on Tags in the topbar;
5. You should see under the "OS/ARCH" field the multiple architectures.

## Deploy the container on a Digital Ocean droplet

_This section assumes that the Digital Ocean Droplet is already shipped with
Docker, but you can also create a Docker droplet using a Docker image from the
Digital Ocean marketplace._

### Setup SSH communication between your machine and the droplet

_You need to do this procedure only once_.

To connect to the droplet, we will use `SSH`. With this utility we can use the CLI of the droplet directly from our machine.
To properly set up SSH communication, refer to the following resources on Digital Ocean:

1. [Overview](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/)
2. [Create SSH Key on your machine](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/create-with-openssh/)
3. [Enable your key on the droplet](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/to-existing-droplet/)
4. [Test your connection](https://docs.digitalocean.com/products/droplets/how-to/connect-with-ssh/openssh/)

_Tip: when you enter a remote machine from your terminal you should see a difference in the header of the CLI commands (eg: `gmarraff@localmachine:` -> `root@remotemachine:`). This will give confirmation that you actually entered the remote machine._

### First deployment (Intel architecture example)

```bash
DROPLET_IP="ip of your droplet"
DROPLET_USERNAME="username of your droplet, usually 'root'"
DOCKERHUB_USERNAME="The name you registered with"
ACCESS_TOKEN="The token saved before"

# SSH into the droplet
ssh $DROPLET_USERNAME@$DROPLET_IP
# If the previous section was executed properly, you should
# now be executing commands directly in the DO droplet.

# Login to Docker Hub. It is required to have permissions to
# pull the image.
docker login -u $DOCKERHUB_USERNAME -p $ACCESS_TOKEN

# Run the container.
# We run it without the --rm flag so that if the container
# crashes for any reason, we can always retrieve the logs.
docker run --name web-call.cc -p 8080:80 -d \
    $DOCKERHUB_USERNAME/web-call.cc:latest

# Exit the droplet and return to your local machine.
exit
```

### Upgrade

```bash
# SSH into the droplet.
ssh $DROPLET_USERNAME@$DROPLET_IP

# Pull the image from the registry. This will download the
# image from the registry and make it accessible from the
# Docker daemon. The first thing we do is the pull because
# it is a network operation and might take some time, and
# we want to minimize the downtime.
docker pull $DOCKERHUB_USERNAME/web-call.cc:latest
docker stop web-call.cc
docker rm web-call.cc
docker run --name web-call.cc -p 8080:80 -d \
    $DOCKERHUB_USERNAME/web-call.cc:latest

# If the last command fails it will print information in
# the CLI output. To rollback to a working status we just
# need to "docker run" with the previous tag. (In
# production we shouldn't use the latest tag.)

# Exit the droplet
exit
```

_A Docker tag can always be overridden. It's usually a good practice to have a "latest" tag for every repository that is upgraded
at every new release. Of course it is also best practice to number your release properly.
Every time you run `docker pull', it will check if the tag changed on the registry and download it again._

## Cleanup unused Docker images

To avoid having the server fill up with unused Docker images, you can install a cron job that removes every image
not currently used by a container.

```bash
docker images prune -a
```

## More Docker commands

docker rm      - remove a container

docker rmi     - remove an image

## TODOs

1. Check how the traffic is directed on the docker container.
2. Check with Thomas the current SSL setup.
3. Define a script to reduce verbosity.
