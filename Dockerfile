FROM ubuntu:20.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install ALL required dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    ninja-build \
    build-essential \
    flex \
    bison \
    git \
    cmake \
    meson \
    pkg-config \
    libpcsclite-dev \
    libsctp-dev \
    libgnutls28-dev \
    libgcrypt-dev \
    libssl-dev \
    libmongoc-dev \
    libbson-dev \
    libyaml-dev \
    libnghttp2-dev \
    libmicrohttpd-dev \
    libcurl4-gnutls-dev \
    libtins-dev \
    libtalloc-dev \
    iproute2 \
    iputils-ping \
    net-tools \
    tmux \
    vim \
    wget \
    curl \
    sqlite3 \
    gnupg \
    swig \
    && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg && \
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
    apt-get update && apt-get install -y mongodb-mongosh && \
    mongosh --version && \
    rm -rf /var/lib/apt/lists/*

# First, upgrade the build tools to their latest versions
RUN python3 -m pip install --upgrade --no-cache-dir pip setuptools wheel

# Install libidn development package
RUN apt-get update && \
    (apt-get install -y libidn-dev || apt-get install -y libidn11-dev) && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies for OTA testing
RUN pip3 install smpplib pymongo pycrypto pyscard

# Create working directory and copy all files
WORKDIR /ota-testing
COPY . /ota-testing/

# Configure Git to use GitHub PAT to avoid rate limits
ARG GITHUB_PAT
RUN git config --global url."https://${GITHUB_PAT}:x-oauth-basic@github.com/".insteadOf "https://github.com/"

# 2. now install the project requirements
RUN pip3 install --no-cache-dir \
    --extra-index-url https://www.piwheels.org/simple \
    -r requirements.txt

# Install prometheus-cpp from source
RUN cd /tmp && \
    git clone https://github.com/jupp0r/prometheus-cpp.git && \
    cd prometheus-cpp && \
    git submodule init && \
    git submodule update && \
    mkdir build && cd build && \
    cmake .. -DENABLE_TESTING=OFF && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    rm -rf /tmp/prometheus-cpp

# Create required directories
RUN mkdir -p /ota-testing/{logs,data,repos}

# Make scripts executable
RUN chmod +x /ota-testing/scripts/*.sh

# Install Open5GS from source
RUN cd /ota-testing && \
    echo "Cloning Open5GS repository..." && \
    git clone https://github.com/open5gs/open5gs.git repos/open5gs && \
    cd repos/open5gs && \
    echo "Configuring Open5GS build with Meson..." && \
    meson build --prefix=/usr/local -Dmetrics_impl=prometheus && \
    echo "Building Open5GS with Ninja..." && \
    ninja -C build -v && \
    echo "Installing Open5GS..." && \
    ninja -C build install && \
    ldconfig && \
    echo "Open5GS installation completed successfully" && \
    ls -la /usr/local/bin/open5gs-*

# Update PATH
ENV PATH="/usr/local/bin:$PATH"

# Expose ports
EXPOSE 2775 3000 8080

# Set entrypoint
ENTRYPOINT ["/ota-testing/scripts/docker-entrypoint.sh"]
