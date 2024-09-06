# Use Debian slim as base image
FROM debian:bullseye-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    make \
    g++ \
    git \
    libfuse-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-thread-dev \
    python3-pip \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Conan
RUN pip3 install conan==1.60.1

# Clone and build cryfs
RUN git clone https://github.com/cryfs/cryfs.git /cryfs && \
    cd /cryfs && \
    git checkout $(git describe --tags --abbrev=0) && \
    mkdir build && \
    cd build && \
    conan install .. --build=missing && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=off && \
    make -j$(nproc) && \
    make install

# Create final minimal image
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    fuse \
    libboost-filesystem1.74.0 \
    libboost-program-options1.74.0 \
    libboost-thread1.74.0 \
    && rm -rf /var/lib/apt/lists/*

# Copy cryfs from builder
COPY --from=builder /usr/local/bin/cryfs /usr/local/bin/cryfs

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/cryfs"]
CMD ["--help"]