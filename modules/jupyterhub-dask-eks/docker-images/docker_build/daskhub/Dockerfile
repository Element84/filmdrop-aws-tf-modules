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

# Install Python dependencies with proper error handling
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    # Core STAC and geospatial dependencies
    pystac==1.10.0 \
    "pystac-client>=0.7.0" \
    "odc-stac>=0.3.8" \
    "planetary_computer>=1.0.0" \
    # Geospatial core
    "geopandas>=0.13.0" \
    "rasterio>=1.3.0" \
    "shapely>=2.0.0" \
    "fiona>=1.9.0" \
    # Data manipulation and analysis
    "pandas>=2.0.0" \
    "numpy>=1.24.0" \
    "xarray>=2023.1.0" \
    # Visualization
    "folium>=0.14.0" \
    "hvplot>=0.8.0" \
    "matplotlib>=3.6.0" \
    "plotly>=5.0.0" \
    # Distributed computing
    "dask[complete]>=2024.1.0,<2025.0.0" \
    "dask-gateway>=2023.1.0" \
    # Jupyter and UI
    jupyterthemes \
    ipywidgets \
    # Database and web
    psycopg2-binary \
    "requests>=2.28.0" \
    # OpenDataCube algorithms
    odc-ui \
    odc-algo

# Set working directory
WORKDIR /home/jovyan/work
