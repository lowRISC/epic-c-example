# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Set up a development environment for the ePIC C example.
#
# Typical workflow for building the image and starting container:
#
#   sudo docker build -t epic .
#   sudo docker run -it epic /bin/bash
#
# Once inside container simply run make. This will take signficant time,
# memory and disk space because LLVM is built as part of the example.
#
#   make

FROM ubuntu:20.04

ENV RISCVTOOLS=/riscv-tools
ENV PATH="${RISCVTOOLS}/bin:${PATH}"

# Modify this to increase or decrease the number of processes that make
# will execute concurrently.
ENV PARALLELISM=8

# Install dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates gnupg build-essential python wget subversion unzip ninja-build cmake device-tree-compiler git clang lld python3 zlib1g zlib1g-dev xxd

# Build the spike simulator.
RUN git clone https://github.com/riscv/riscv-isa-sim && \
    cd riscv-isa-sim && \
    mkdir build && \
    cd build && \
    ../configure --prefix=$RISCVTOOLS && \
    make -j $PARALLELISM && \
    make install

# Copy across the repository and set it as the working directory.
ADD . /epic-c-example
WORKDIR /epic-c-example

# Uncomment the line below to pre-build the example.
# This will take some time because it builds LLVM.
# RUN make kernel
