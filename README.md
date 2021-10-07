# web-cc Docker build

## Build and use the container locally

_This section assumes you have Docker installed and running on your machine.
(See <https://docs.docker.com/get-docker/>)._

```bash
# Build the Docker image.
docker build \
    -t web-cc:latest \ # Name your image to access it later locally.
    .

# List the Docker images present on your computer. You should
# see "web-cc" there.
docker images

# Run your container.
docker run        \
    --rm          \ # Remove the container when stopped. This
                  \ # helps to save space and make the command
                  \ # idempotent.
    --name web-cc \ # Name of container so you can access it
                  \ # later on.
    -d            \ # Run the container in the background
                  \ # (optional).
    -p 8080:80    \ # Map port 80 of the container to port
                  \ # 8080 of your machine. If the 8080 port
                  \ # is busy, please use another one.
    web-cc:latest

# List all the running containers. You should see the "web-cc"
# container there.
docker ps

# Check the logs of your container (in this case httpd logs).
docker logs -f web-cc

# You can now access the website at localhost:8080 .

# Access your container.
docker exec \
    -it \ # Attach the tty to allow interactive operations
    web-cc \ # name of your container
    sh # The executable to run

# Stop and remove the container.
docker stop web-cc

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
4. Type "web-cc" as the name and "web-cc app" as the Description;
5. Flag it as "Private";
6. Click "Create"

### Push the local image to Docker Hub

```bash
DOCKERHUB_USERNAME="The name you registred with"
ACCESS_TOKEN="The token saved before"

# Login into Docker Hub. It is required to have permissions to
# publish the image.
docker login -u $DOCKERHUB_USERNAME -p $ACCESS_TOKEN

# This login might print "WARNING! Using --password via the CLI
# is insecure. Use --password-stdin."

# Tag the image by specifying the correct repository and
# a useful tag (the hub.docker.com prefix is implicit).
docker tag web-cc $DOCKERHUB_USERNAME/web-cc:latest

# Push the image to Docker Hub.
docker push $DOCKERHUB_USERNAME/web-cc:latest
```

## Deploy the container on a Digital Ocean droplet

_This section assumes that the DO Droplet is already shipped with Docker, but you can also create a Docker droplet using a Docker image from the marketplace._

### Setup SSH communication between your machine and the droplet

_You need to do this procedure only once_.

To connect to the droplet, we will use `SSH`. With this utility we can use the CLI of the droplet directly from our machine.
To properly set up SSH communication, refer to the following resources on Digital Ocean:

1. [Overview](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/)
2. [Create SSH Key on your machine](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/create-with-openssh/)
3. [Enable your key on the droplet](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/to-existing-droplet/)
4. [Test your connection](https://docs.digitalocean.com/products/droplets/how-to/connect-with-ssh/openssh/)

_Tip: when you enter a remote machine from your terminal you should see a difference in the header of the CLI commands (eg: `gmarraff@localmachine:` -> `root@remotemachine:`). This will give confirmation that you actually entered the remote machine._

### First deployment

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
docker run --name web-cc -p 8080:80 -d \
    $DOCKERHUB_USERNAME/web-cc:latest

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
docker pull $DOCKERHUB_USERNAME/web-cc:latest
docker stop web-cc
docker rm web-cc
docker run --name web-cc -p 8080:80 -d \
    $DOCKERHUB_USERNAME/web-cc:latest

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

## TODOs

1. Set up the Digital Ocean droplet (SSH keys installation).
2. Check how the traffic is directed on the docker container.
3. Check with Thomas the current SSL setup.
4. Define a script to reduce verbosity.
