# FROM is the first section of a Dockerfile, it indicates from which image to base ours
# We use the official httpd one, that it is really simple to use: https://hub.docker.com/_/httpd
# The alpine images are really small but have minimal set of system libraries, since we don't need
# to perform any additional operations, it is best to use it to save network traffic when pulling the image
FROM httpd:2.4.50-alpine

# Allow the container to run as www-data for security (https://github.com/docker-library/httpd/issues/102)
RUN apk update && apk upgrade
RUN apk -q add curl vim libcap
# Change access righs to conf, logs, bin from root to www-data
RUN chown -hR www-data:www-data /usr/local/apache2/
# setcap to bind to privileged ports as non-root
RUN setcap 'cap_net_bind_service=+ep' /usr/local/apache2/bin/httpd
RUN getcap /usr/local/apache2/bin/httpd

USER www-data

# We copy the "build" folder on our machine into the container htdocs.
# The default configuration of httpd looks for the htdocs in /usr/local/apache2/htdocs/,
# so we don't need to do more
COPY ./build/ /usr/local/apache2/htdocs/

# When starting the container, this image will start the httpd daemon, this behaviour is
# inherited from the base image.