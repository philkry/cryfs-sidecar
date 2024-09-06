# Use a small base image
FROM alpine:3.18 as builder

# Install build dependencies
RUN apk add --no-cache \
    cmake \
    make \
    g++ \
    git \
    curl \
    fuse-dev \
    openssl-dev \
    boost-dev \
    python3 \
    py3-pip

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
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache \
    fuse \
    libstdc++ \
    boost-program_options \
    boost-filesystem \
    boost-system

# Copy cryfs from builder
COPY --from=builder /usr/local/bin/cryfs /usr/local/bin/cryfs

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/cryfs"]
CMD ["--help"]