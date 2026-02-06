FROM ubuntu:focal

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ARG DEBIAN_FRONTEND=noninteractive

# Style dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates gnupg postgresql-client curl unzip python3 \
    python-is-python3 python3-pip python3-venv git \
    fonts-unifont mapnik-utils build-essential \
    && curl -fsSL https://deb.nodesource.com/setup_12.x | bash - \
    && apt-get install --no-install-recommends -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Kosmtik with plugins, forcing prefix to /usr because Ubuntu sets
# npm prefix to /usr/local, which breaks the install
# We install kosmtik not from release channel, but directly from a specific commit on github.
# c0152c13918635bdaa05b08078f2f7b3c9439a10 is pinned for Node 12 compatibility.
RUN npm set prefix /usr && npm install -g --unsafe-perm "git+https://git@github.com/kosmtik/kosmtik.git#c0152c13918635bdaa05b08078f2f7b3c9439a10"

WORKDIR /usr/lib/node_modules/kosmtik/
RUN kosmtik plugins --install kosmtik-overpass-layer \
                    --install kosmtik-fetch-remote \
                    --install kosmtik-overlay \
                    --install kosmtik-open-in-josm \
                    --install kosmtik-map-compare \
                    --install kosmtik-osm-data-overlay \
                    --install kosmtik-mapnik-reference \
                    --install kosmtik-geojson-overlay \
                    --install kosmtik-mbtiles-export \
    && cp /root/.config/kosmtik.yml /tmp/.kosmtik-config.yml

# Closing section
RUN mkdir -p /openstreetmap-carto
WORKDIR /openstreetmap-carto

USER 1000
CMD sh scripts/docker-startup.sh kosmtik
