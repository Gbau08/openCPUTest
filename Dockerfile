# Use the official OpenCPU Dockerfile as a base
FROM opencpu/base

# Put a copy of our R code into the container
WORKDIR /usr/local/src
COPY . /usr/local/src/app

# Run our custom install script to install R dependencies
RUN /usr/bin/R --vanilla -f app/docker/installer.R

# Install our code as an R package on the server
RUN tar czf /tmp/dummyOpenTargetData.tar.gz app/ \
&& /usr/bin/R CMD INSTALL /tmp/dummyOpenTargetData.tar.gz