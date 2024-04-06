FROM rust:latest

# @link https://kerkour.com/rust-cross-compilation

ARG CONTAINER_USER="developer"
ARG CONTAINER_UID="1000"
ARG CONTAINER_GID="1000"

ENV CONTAINER_USER=${CONTAINER_USER} \
    UID=${CONTAINER_UID} \
    GID=${CONTAINER_GID}

RUN apt update
# RUN apt upgrade -y
RUN apt install -y g++-aarch64-linux-gnu libc6-dev-arm64-cross

RUN rustup target add aarch64-unknown-linux-gnu
RUN rustup toolchain install stable-aarch64-unknown-linux-gnu

# Creating the USER
RUN groupadd -g ${GID} "${CONTAINER_USER}" && \
    useradd --create-home --uid "${UID}" --gid "${GID}" "${CONTAINER_USER}"

WORKDIR /home/developer/workspace

ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc \
    CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc \
    CXX_aarch64_unknown_linux_gnu=aarch64-linux-gnu-g++

CMD ["cargo", "build", "--target", "aarch64-unknown-linux-gnu"]
