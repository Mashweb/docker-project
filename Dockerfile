# The `FROM' section of a Dockerfile indicates which image to base ours on.
# We base our image on the official httpd image,
# `https://hub.docker.com/_/httpd', which is simple to use. The alpine images
# are small and have minimal set of system libraries, but since we don't need
# to perform any additional operations using an alpine image is good because
# it saves network traffic when pulling the image.
FROM httpd:2.4.50-alpine

# Allow the container to run as www-data for security reasons
# (https://github.com/docker-library/httpd/issues/102).
RUN apk update && apk upgrade
RUN apk -q add curl vim libcap
# Change access rights to conf, logs, bin from root to www-data.
RUN chown -hR www-data:www-data /usr/local/apache2/
# Use setcap to bind to privileged ports as non-root.
RUN setcap 'cap_net_bind_service=+ep' /usr/local/apache2/bin/httpd

USER www-data

# We copy the "web_docs" folder on our machine into the container htdocs.
# The default configuration of httpd looks for the htdocs in
# /usr/local/apache2/htdocs/, so we don't need to do more.
COPY ./web_docs/ /usr/local/apache2/htdocs/

# When starting the container, this image will start the httpd daemon,
# this behaviour is inherited from the base image.
