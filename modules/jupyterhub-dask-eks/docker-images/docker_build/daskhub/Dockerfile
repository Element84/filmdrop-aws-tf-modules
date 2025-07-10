FROM pangeo/pangeo-notebook:2025.06.02
LABEL maintainer="open-source@element84.com"

USER root

# Install system dependencies
RUN apt-get update && apt-get -y install \
    gcc \
    g++ \
    libgdal-dev \
    gdal-bin \
    && rm -rf /var/lib/apt/lists/*

# The default non-root user in Jupyter Docker Images
USER jovyan

# Install Python dependencies with porper version locking
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    pystac==1.13.0 \
    pystac-client==0.8.6 \
    odc-stac==0.3.11 \
    odc-ui==0.2.1 \
    odc-algo==1.0.1 \
    dask==2024.8.0 \
    dask-gateway==2024.1.0 \
    planetary-computer==1.0.0 \
    geopandas==1.0.1 \
    rasterio==1.4.3 \
    shapely==2.1.1 \
    fiona==1.10.1 \
    pandas==2.2.3 \
    numpy==2.2.6 \
    xarray==2025.4.0 \
    folium==0.19.6 \
    hvplot==0.11.3 \
    matplotlib==3.10.3 \
    plotly==6.2.0 \
    jupyterthemes==0.20.0 \
    ipywidgets==8.1.7 \
    psycopg2-binary==2.9.10 \
    requests==2.32.3

# Set working directory
WORKDIR /home/jovyan/work
