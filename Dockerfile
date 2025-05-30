FROM ubuntu:22.04

# Use Ubuntu 22.04 for better compatibility
ENV DEBIAN_FRONTEND=noninteractive
ENV UHD_TAG=v4.6.0.0
ENV MAKEWIDTH=4

# Install dependencies with proper Python support
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
        # Add missing dependencies
        pkg-config \
        libssl-dev \
        wget \
        curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies that might be missing
RUN pip3 install \
    mako \
    ruamel.yaml \
    requests \
    packaging

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

USER root

# Download UHD images (this can take time)
RUN /opt/uhd/install/bin/uhd_images_downloader || echo "Image download failed, continuing..."

# Create verification script
RUN echo '#!/bin/bash\n\
echo "=== UHD Build Verification ==="\n\
echo "UHD Version:"\n\
/opt/uhd/install/bin/uhd_config_info --version\n\
echo ""\n\
echo "Python API Test:"\n\
python3 -c "import uhd; print(f\"UHD Python API loaded successfully: {uhd.get_version_string()}\")" || echo "Python API failed"\n\
echo ""\n\
echo "USRP Detection (requires hardware):"\n\
/opt/uhd/install/bin/uhd_find_devices || echo "No USRP devices found (normal without hardware)"\n\
' > /opt/uhd/verify_uhd.sh && \
    chmod +x /opt/uhd/verify_uhd.sh

WORKDIR /opt/uhd
CMD ["/bin/bash"] 