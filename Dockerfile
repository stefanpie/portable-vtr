############################################
# 1) Builder stage: compile VTR v9.0.0     #
############################################
FROM ubuntu:22.04 AS builder

# avoid tzdata prompts
ENV DEBIAN_FRONTEND=noninteractive

# allow build-time overrides
ARG BUILD_TYPE=Release
ARG CMAKE_PARAMS=""


RUN apt-get update

# Base packages to compile and run basic regression tests
RUN apt-get install -y --no-install-recommends\
    make \
    cmake \
    build-essential \
    pkg-config \
    bison \
    flex \
    python3-dev \
    python3-venv \
    ca-certificates

# Packages for more complex features of VTR that most people will use.
RUN apt-get install -y --no-install-recommends\
    libtbb-dev \
    libeigen3-dev\
    zlib1g-dev \
    xsltproc

# Required for graphics
# RUN apt-get install -y --no-install-recommends\
#     libgtk-3-dev \
#     libx11-dev

# Required for parmys front-end from https://github.com/YosysHQ/yosys
RUN apt-get install -y --no-install-recommends\
    build-essential \
    clang \
    bison \
    flex \
    libreadline-dev \
    libedit-dev \
    gawk \
    tcl-dev \
    libffi-dev \
    git \
    graphviz \
    xdot \
    pkg-config \
    python3-dev \
    libboost-system-dev \
    libboost-python-dev \
    libboost-filesystem-dev \
    default-jre \
    zlib1g-dev

# Required to build the documentation
# RUN apt-get install -y --no-install-recommends\
#     sphinx-common


RUN apt-get autoclean && apt-get clean && apt-get -y autoremove
RUN rm -rf /var/lib/apt/lists/*

# install Python doc requirements
# COPY doc/requirements.txt /tmp/requirements.txt
# RUN python3 -m pip install --no-cache-dir -r /tmp/requirements.txt



# fetch VTR v9.0.0
WORKDIR /src
RUN git clone --depth 1 \
    --branch v9.0.0 \
    --single-branch \
    https://github.com/verilog-to-routing/vtr-verilog-to-routing.git vtr


# init submodules
WORKDIR /src/vtr
RUN git submodule update --init --recursive

WORKDIR /src/vtr/
COPY abc-cmake /tmp/abc-cmake
RUN cp /tmp/abc-cmake abc/CMakeLists.txt

RUN cat /src/vtr/abc/CMakeLists.txt


# prepare build directory
WORKDIR /src/vtr
RUN mkdir build
WORKDIR /src/vtr/build



# configure, build, install, and generate docs
RUN cmake .. \
    ${CMAKE_PARAMS} \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX=/opt/vtr \
    -DCMAKE_FIND_LIBRARY_SUFFIXES=".a;.lib" \
    -DCMAKE_EXE_LINKER_FLAGS="-static -static-libgcc -static-libstdc++ -pthread" \
    -DZLIB_USE_STATIC_LIBS=ON \
    -DZLIB_LIBRARY=/usr/lib/x86_64-linux-gnu/libz.a \
    -DZLIB_INCLUDE_DIR=/usr/include \
    -DVPR_EXECUTION_ENGINE=serial \
    -DTATUM_EXECUTION_ENGINE=serial \
    -DWITH_PARMYS=ON \
    -DWITH_ABC=ON \
    -DVPR_USE_EZGL=off \
    -DVTR_ENABLE_CAPNPROTO=OFF



# RUN make -j$(nproc)
RUN make -j64
RUN make install

# ############################################
# # 2) Final stage: tiny runtime image       #
# ############################################
# FROM scratch

# # copy the fully static install
# COPY --from=builder /opt/vtr /opt/vtr

# # add binaries and docs to PATH
# ENV PATH="/opt/vtr/bin:${PATH}"

# # default entrypoint
# ENTRYPOINT ["vpr"]
