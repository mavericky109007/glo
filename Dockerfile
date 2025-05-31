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
    mongodb-clients \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Install libidn development package
RUN apt-get update && \
    (apt-get install -y libidn-dev || apt-get install -y libidn11-dev) && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip and install Meson
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install meson ninja

# Verify Meson installation
RUN meson --version && ninja --version

# Install Python dependencies for OTA testing
RUN pip3 install smpplib pymongo pycrypto

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

# Create working directory
WORKDIR /ota-testing

# Copy all files including pre-created scripts and configs
COPY . /ota-testing/

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
