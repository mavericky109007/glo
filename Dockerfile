FROM ubuntu:22.04

# Use Ubuntu 22.04 for better compatibility (includes liburing-dev)
ENV DEBIAN_FRONTEND=noninteractive
ENV UHD_TAG=v4.6.0.0
ENV MAKEWIDTH=4
ENV TZ=UTC

# Configure DNS and update package lists
RUN apt-get update --fix-missing && \
    apt-get install -y \
        pkg-config \
        pkgconf \
        build-essential \
        autotools-dev \
        autoconf \
        automake \
        libtool \
        git \
        cmake \
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
        libssl-dev \
        wget \
        curl \
        # Osmocom dependencies (liburing-dev available in Ubuntu 22.04)
        liburing-dev \
        libmnl-dev \
        libtalloc-dev \
        libpcsclite-dev \
        libsctp-dev \
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
        libgcrypt20-dev \
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

# Set environment variables for proper library discovery
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

# Verify critical dependencies before building
RUN echo "Verifying critical dependencies..." && \
    pkg-config --modversion liburing && echo "✅ liburing available" && \
    pkg-config --modversion libmnl && echo "✅ libmnl available" || \
    (echo "❌ Critical dependencies missing, building from source..." && \
     cd /tmp && \
     # Build liburing if missing
     if ! pkg-config --exists liburing; then \
         git clone https://github.com/axboe/liburing.git && \
         cd liburing && \
         ./configure --prefix=/usr/local && \
         make -j$(nproc) && \
         make install && \
         ldconfig && \
         cd /tmp; \
     fi && \
     # Build libmnl if missing
     if ! pkg-config --exists libmnl; then \
         wget https://netfilter.org/projects/libmnl/files/libmnl-1.0.5.tar.bz2 && \
         tar -xjf libmnl-1.0.5.tar.bz2 && \
         cd libmnl-1.0.5 && \
         ./configure --prefix=/usr && \
         make && \
         make install && \
         ldconfig && \
         cd /tmp; \
     fi && \
     echo 'export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"' >> /etc/environment && \
     cd / && rm -rf /tmp/* && \
     pkg-config --modversion liburing && echo "✅ liburing ready" && \
     pkg-config --modversion libmnl && echo "✅ libmnl ready")

# Install Python dependencies that might be missing
RUN pip3 install --no-cache-dir \
    mako \
    ruamel.yaml \
    smpplib \
    pyscard \
    click \
    pyyaml

# Create uhd user for UHD build
RUN useradd -m -s /bin/bash uhd && \
    mkdir -p /opt/uhd && \
    chown uhd:uhd /opt/uhd

# Switch to uhd user for UHD build
USER uhd
WORKDIR /opt/uhd

# Clone UHD with timeout and retry logic
RUN timeout 3600 git clone --depth 1 --branch ${UHD_TAG} https://github.com/EttusResearch/uhd.git uhd-source || \
    (echo "Git clone timed out or failed, trying shallow clone..." && \
     git clone --depth 1 https://github.com/EttusResearch/uhd.git uhd-source)

# Build UHD with proper configuration and RPATH
RUN cd uhd-source/host && \
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
        -DCMAKE_INSTALL_RPATH=/opt/uhd/install/lib \
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
        .. && \
    make -j${MAKEWIDTH} && \
    make install

# Set up environment
ENV PATH="/opt/uhd/install/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/uhd/install/lib:${LD_LIBRARY_PATH}"
ENV PYTHONPATH="/opt/uhd/install/lib/python3/dist-packages:${PYTHONPATH}"

# Switch back to root for system-wide installations
USER root

# Download UHD images
RUN /opt/uhd/install/bin/uhd_images_downloader || echo "Image download failed, continuing..."

# Build Osmocom components in correct order with proper environment
WORKDIR /opt/build

# Verify dependencies are available before building Osmocom components
RUN pkg-config --exists liburing && pkg-config --modversion liburing && \
    pkg-config --exists libmnl && pkg-config --modversion libmnl || \
    (echo "ERROR: Required dependencies not found" && exit 1)

# Build libosmocore first (foundation library)
RUN git clone https://gitea.osmocom.org/osmocom/libosmocore.git && \
    cd libosmocore && \
    autoreconf -i && \
    ./configure && \
    make -j${MAKEWIDTH} && \
    make install && \
    ldconfig && \
    cd ..

# Build libosmo-netif (depends on libosmocore)
RUN git clone https://gitea.osmocom.org/osmocom/libosmo-netif.git && \
    cd libosmo-netif && \
    autoreconf -i && \
    ./configure && \
    make -j${MAKEWIDTH} && \
    make install && \
    ldconfig && \
    cd ..

# Build libosmo-abis with DAHDI disabled (depends on libosmocore and libosmo-netif)
RUN git clone https://gitea.osmocom.org/osmocom/libosmo-abis.git && \
    cd libosmo-abis && \
    autoreconf -i && \
    ./configure --disable-dahdi && \
    make -j${MAKEWIDTH} && \
    make install && \
    ldconfig

# Install OsmoMSC (depends on all above libraries)
RUN git clone https://gitea.osmocom.org/cellular-infrastructure/osmo-msc && \
    cd osmo-msc && \
    autoreconf -i && \
    ./configure --enable-smpp && \
    make -j${MAKEWIDTH} && \
    make install && \
    ldconfig

# Install OsmoHLR (depends on libosmocore)
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

# Create OTA applet directory and download reference implementation
WORKDIR /opt/ota
RUN git clone https://github.com/ryantheelder/OTAapplet.git applets || \
    (echo "Creating placeholder applet directory..." && \
     mkdir -p applets && \
     echo "# OTA Applet Directory" > applets/README.md && \
     echo "Place your OTA applet implementations here" >> applets/README.md)

# Setup TUN interface script
COPY scripts/setup-tun.sh /usr/local/bin/setup-tun.sh
RUN chmod +x /usr/local/bin/setup-tun.sh

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
echo "4. Critical Dependencies:"\n\
pkg-config --modversion liburing && echo "✓ liburing available" || echo "✗ liburing missing"\n\
pkg-config --modversion libmnl && echo "✓ libmnl available" || echo "✗ libmnl missing"\n\
echo ""\n\
echo "5. Osmocom Components:"\n\
which osmo-msc && echo "✓ OsmoMSC installed" || echo "✗ OsmoMSC missing"\n\
which osmo-hlr && echo "✓ OsmoHLR installed" || echo "✗ OsmoHLR missing"\n\
echo ""\n\
echo "6. Open5GS Components:"\n\
which open5gs-mmed && echo "✓ Open5GS MME installed" || echo "✗ Open5GS MME missing"\n\
which open5gs-hssd && echo "✓ Open5GS HSS installed" || echo "✗ Open5GS HSS missing"\n\
echo ""\n\
echo "7. OTA Applets:"\n\
ls -la /opt/ota/applets/ && echo "✓ Applet directory available" || echo "✗ Applet directory missing"\n\
echo ""\n\
echo "8. USRP Detection (requires hardware):"\n\
/opt/uhd/install/bin/uhd_find_devices || echo "No USRP devices found (normal without hardware)"\n\
echo ""\n\
echo "=== Verification Complete ==="\n\
' > /opt/verify_complete.sh && \
    chmod +x /opt/verify_complete.sh

WORKDIR /opt
CMD ["/bin/bash"] 