FROM ubuntu:22.04

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Set working directory
WORKDIR /ota-testing

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    cmake \
    git \
    wget \
    curl \
    pkg-config \
    autoconf \
    automake \
    libtool \
    flex \
    bison \
    ninja-build \
    meson \
    # Python and development
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    # Smart card dependencies (fixes pyscard error)
    swig \
    libpcsclite-dev \
    pcscd \
    libccid \
    libusb-dev \
    # Libraries
    libssl-dev \
    libusb-1.0-0-dev \
    libfftw3-dev \
    libboost-all-dev \
    libsctp-dev \
    libconfig++-dev \
    libmbedtls-dev \
    libgnutls28-dev \
    libgcrypt-dev \
    libidn11-dev \
    libmongoc-dev \
    libbson-dev \
    libyaml-dev \
    libnghttp2-dev \
    libmicrohttpd-dev \
    libcurl4-gnutls-dev \
    libtins-dev \
    libtalloc-dev \
    libncurses-dev \
    # Network tools
    tmux \
    telnet \
    netcat \
    tcpdump \
    # Java for SIM tools
    default-jdk \
    # Additional utilities
    vim \
    nano \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies in stages to handle pyscard properly
RUN pip3 install --no-cache-dir \
    smpplib \
    pycryptodome \
    requests \
    pyyaml \
    numpy \
    scipy \
    mako \
    ruamel.yaml

# Install pyscard separately after system dependencies are in place
RUN pip3 install --no-cache-dir pyscard

# Create directory structure
RUN mkdir -p repos configs scripts logs applets

# Copy configuration files and scripts
COPY configs/ ./configs/
COPY scripts/ ./scripts/

# Set executable permissions
RUN chmod +x scripts/*.sh scripts/*.py

# Install UHD (for USRP support) with proper dependencies
RUN cd repos && \
    git clone https://github.com/EttusResearch/uhd.git && \
    cd uhd/host && \
    python3 -c "import mako; import ruamel.yaml; print('✓ UHD dependencies verified')" && \
    mkdir build && cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Install srsRAN_4G
RUN cd repos && \
    git clone https://github.com/srsRAN/srsRAN_4G.git && \
    cd srsRAN_4G && \
    mkdir build && cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install

# Install Osmocom components
RUN cd repos && \
    # libosmocore
    git clone https://gitea.osmocom.org/osmocom/libosmocore.git && \
    cd libosmocore && \
    autoreconf -i && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd .. && \
    # libosmo-abis
    git clone https://gitea.osmocom.org/osmocom/libosmo-abis.git && \
    cd libosmo-abis && \
    autoreconf -i && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd .. && \
    # OsmoHLR
    git clone https://github.com/osmocom/osmo-hlr.git && \
    cd osmo-hlr && \
    autoreconf -i && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd .. && \
    # OsmoMSC
    git clone https://gitea.osmocom.org/cellular-infrastructure/osmo-msc && \
    cd osmo-msc && \
    autoreconf -i && \
    ./configure --enable-smpp && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Install Open5GS
RUN cd repos && \
    git clone https://github.com/open5gs/open5gs && \
    cd open5gs && \
    meson build --prefix=/usr/local && \
    ninja -C build && \
    cd build && \
    ninja install

# Install SIM tools
RUN cd repos && \
    git clone https://github.com/herlesupreeth/sim-tools.git && \
    git clone https://github.com/ryantheelder/OTAapplet.git && \
    git clone https://gitea.osmocom.org/sim-card/hello-stk

# Install GlobalPlatformPro
RUN wget -O /usr/local/bin/gp.jar \
    https://github.com/martinpaljak/GlobalPlatformPro/releases/download/v21.05.25/gp.jar && \
    echo '#!/bin/bash\njava -jar /usr/local/bin/gp.jar "$@"' > /usr/local/bin/gp && \
    chmod +x /usr/local/bin/gp

# Setup TUN interface script
RUN echo '#!/bin/bash\n\
ip tuntap add name ogstun mode tun\n\
ip addr add 10.45.0.1/16 dev ogstun\n\
ip addr add 2001:db8:cafe::1/48 dev ogstun\n\
ip link set ogstun up' > /usr/local/bin/setup-tun.sh && \
    chmod +x /usr/local/bin/setup-tun.sh

# Verify installations
RUN python3 -c "import smartcard; print('✓ pyscard installed successfully')" && \
    python3 -c "import smpplib; print('✓ smpplib installed successfully')" && \
    python3 -c "import mako; import ruamel.yaml; print('✓ UHD dependencies verified')" && \
    which open5gs-mmed && echo "✓ Open5GS installed" && \
    which osmo-msc && echo "✓ OsmoMSC installed" && \
    uhd_find_devices && echo "✓ UHD installed successfully"

# Expose ports for various services
EXPOSE 2755 3000 4258 9090

# Set default command
CMD ["/bin/bash"] 