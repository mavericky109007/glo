FROM ubuntu:22.04

# Use Ubuntu 22.04 for better compatibility (includes liburing-dev)
ENV DEBIAN_FRONTEND=noninteractive
ENV UHD_TAG=v4.6.0.0
ENV MAKEWIDTH=4

# Install dependencies with proper Python support and liburing
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        cmake \
        git \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        libboost-all-dev \
        libusb-1.0-0-dev \
        libudev-dev \
        libncurses5-dev \
        libfftw3-bin \
        libfftw3-dev \
        libfftw3-doc \
        libcppunit-1.15-0 \
        libcppunit-dev \
        libcppunit-doc \
        ncurses-bin \
        cpufrequtils \
        python3-numpy \
        python3-cheetah \
        python3-lxml \
        doxygen \
        libqwt-qt5-dev \
        libqt5opengl5-dev \
        python3-pyqt5 \
        liblog4cpp5-dev \
        libzmq3-dev \
        python3-yaml \
        python3-click \
        python3-click-plugins \
        python3-zmq \
        python3-scipy \
        python3-gi-cairo \
        gir1.2-gtk-3.0 \
        libcodec2-dev \
        libgsm1-dev \
        pybind11-dev \
        python3-pybind11 \
        # Essential dependencies
        pkg-config \
        libssl-dev \
        wget \
        curl \
        # Osmocom dependencies (liburing-dev available in Ubuntu 22.04)
        liburing-dev \
        libtalloc-dev \
        libpcsclite-dev \
        libsctp-dev \
        autoconf \
        automake \
        libtool \
        # Smart card dependencies
        swig \
        pcscd \
        libccid \
        # Open5GS dependencies
        flex \
        bison \
        ninja-build \
        meson \
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
        && apt-get clean && \
        rm -rf /var/lib/apt/lists/*

# Verify liburing installation
RUN pkg-config --modversion liburing && echo "✅ liburing available" || \
    (echo "❌ liburing not found, building from source..." && \
     cd /tmp && \
     git clone https://github.com/axboe/liburing.git && \
     cd liburing && \
     ./configure --prefix=/usr/local && \
     make -j$(nproc) && \
     make install && \
     ldconfig && \
     echo 'export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"' >> /etc/environment && \
     cd / && rm -rf /tmp/liburing && \
     pkg-config --modversion liburing && echo "✅ liburing built from source")

# Install Python dependencies that might be missing
RUN pip3 install \
    mako \
    ruamel.yaml \
    requests \
    packaging \
    smpplib \
    pycryptodome \
    pyscard

# Create uhd user and directories
RUN useradd -m -s /bin/bash uhd && \
    mkdir -p /opt/uhd && \
    chown uhd:uhd /opt/uhd

USER uhd
WORKDIR /opt/uhd

# Clone UHD with timeout and retry logic
RUN timeout 3600 git clone --depth 1 --branch ${UHD_TAG} https://github.com/EttusResearch/uhd.git uhd-source || \
    (echo "Git clone timed out or failed, trying shallow clone..." && \
     git clone --depth 1 https://github.com/EttusResearch/uhd.git uhd-source)

# Build UHD with proper configuration
RUN cd uhd-source && \
    mkdir build && \
    cd build && \
    cmake \
        -DCMAKE_INSTALL_PREFIX=/opt/uhd/install \
        -DENABLE_PYTHON_API=ON \
        -DENABLE_PYTHON3=ON \
        -DPYTHON_EXECUTABLE=/usr/bin/python3 \
        -DENABLE_TESTS=OFF \
        -DENABLE_E100=OFF \
        -DENABLE_E300=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_STATIC_LIBS=OFF \
        -DENABLE_SHARED_LIBS=ON \
        .. && \
    make -j${MAKEWIDTH} && \
    make install

# Set up environment
ENV PATH="/opt/uhd/install/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/uhd/install/lib:${LD_LIBRARY_PATH}"
ENV PYTHONPATH="/opt/uhd/install/lib/python3/dist-packages:${PYTHONPATH}"
ENV UHD_IMAGES_DIR="/opt/uhd/install/share/uhd/images"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}"

USER root

# Download UHD images (this can take time)
RUN /opt/uhd/install/bin/uhd_images_downloader || echo "Image download failed, continuing..."

# Build Osmocom components with liburing support
WORKDIR /opt/build

# Verify liburing is available before building Osmocom components
RUN pkg-config --exists liburing && pkg-config --modversion liburing || \
    (echo "ERROR: liburing not found" && exit 1)

# Install libosmocore (now with liburing available)
RUN git clone https://gitea.osmocom.org/osmocom/libosmocore.git && \
    cd libosmocore && \
    autoreconf -i && \
    ./configure && \
    make -j${MAKEWIDTH} && \
    make install && \
    ldconfig

# Install libosmo-abis
RUN git clone https://gitea.osmocom.org/osmocom/libosmo-abis.git && \
    cd libosmo-abis && \
    autoreconf -i && \
    ./configure && \
    make -j${MAKEWIDTH} && \
    make install && \
    ldconfig

# Install libosmo-netif
RUN git clone https://gitea.osmocom.org/osmocom/libosmo-netif.git && \
    cd libosmo-netif && \
    autoreconf -i && \
    ./configure && \
    make -j${MAKEWIDTH} && \
    make install && \
    ldconfig

# Install OsmoMSC
RUN git clone https://gitea.osmocom.org/cellular-infrastructure/osmo-msc && \
    cd osmo-msc && \
    autoreconf -i && \
    ./configure --enable-smpp && \
    make -j${MAKEWIDTH} && \
    make install && \
    ldconfig

# Install OsmoHLR
RUN git clone https://gitea.osmocom.org/cellular-infrastructure/osmo-hlr && \
    cd osmo-hlr && \
    autoreconf -i && \
    ./configure && \
    make -j${MAKEWIDTH} && \
    make install && \
    ldconfig

# Install Open5GS
RUN git clone https://github.com/open5gs/open5gs && \
    cd open5gs && \
    meson build --prefix=/usr/local && \
    ninja -C build && \
    ninja -C build install && \
    ldconfig

# Setup TUN interface script
RUN echo '#!/bin/bash\n\
ip tuntap add name ogstun mode tun\n\
ip addr add 10.45.0.1/16 dev ogstun\n\
ip addr add 2001:db8:cafe::1/48 dev ogstun\n\
ip link set ogstun up' > /usr/local/bin/setup-tun.sh && \
    chmod +x /usr/local/bin/setup-tun.sh

# Create comprehensive verification script
RUN echo '#!/bin/bash\n\
echo "=== Complete OTA Testing Environment Verification ==="\n\
echo ""\n\
echo "1. UHD Version:"\n\
/opt/uhd/install/bin/uhd_config_info --version\n\
echo ""\n\
echo "2. Python API Test:"\n\
python3 -c "import uhd; print(f\"UHD Python API: {uhd.get_version_string()}\")" || echo "UHD Python API failed"\n\
echo ""\n\
echo "3. Python Dependencies:"\n\
python3 -c "import smpplib; print(\"✓ smpplib\")" || echo "✗ smpplib"\n\
python3 -c "import smartcard; print(\"✓ pyscard\")" || echo "✗ pyscard"\n\
python3 -c "import mako; print(\"✓ mako\")" || echo "✗ mako"\n\
python3 -c "import ruamel.yaml; print(\"✓ ruamel.yaml\")" || echo "✗ ruamel.yaml"\n\
echo ""\n\
echo "4. Osmocom Components:"\n\
which osmo-msc && echo "✓ OsmoMSC installed" || echo "✗ OsmoMSC missing"\n\
which osmo-hlr && echo "✓ OsmoHLR installed" || echo "✗ OsmoHLR missing"\n\
echo ""\n\
echo "5. Open5GS Components:"\n\
which open5gs-mmed && echo "✓ Open5GS MME installed" || echo "✗ Open5GS MME missing"\n\
which open5gs-hssd && echo "✓ Open5GS HSS installed" || echo "✗ Open5GS HSS missing"\n\
echo ""\n\
echo "6. liburing verification:"\n\
pkg-config --modversion liburing && echo "✓ liburing available" || echo "✗ liburing missing"\n\
echo ""\n\
echo "7. USRP Detection (requires hardware):"\n\
/opt/uhd/install/bin/uhd_find_devices || echo "No USRP devices found (normal without hardware)"\n\
echo ""\n\
echo "=== Verification Complete ==="\n\
' > /opt/verify_complete.sh && \
    chmod +x /opt/verify_complete.sh

WORKDIR /opt
CMD ["/bin/bash"] 