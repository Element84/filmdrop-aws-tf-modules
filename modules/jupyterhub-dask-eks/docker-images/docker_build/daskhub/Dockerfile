FROM pangeo/pangeo-notebook:2022.12.18
LABEL maintainer="open-source@element84.com"

USER root

# Install build dependencies
RUN apt-get update
RUN apt-get -y install gcc
RUN pip3 install psycopg2-binary

# Install extra dependencies
RUN pip3 install --no-cache pystac==1.10.0 odc-stac planetary_computer jupyterthemes odc-ui odc-algo
