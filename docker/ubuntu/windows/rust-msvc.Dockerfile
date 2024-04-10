FROM rust:latest

ARG HOST_USER_NAME="exadra37"
ARG HOST_UID="1000"
ARG HOST_GID="1000"

ENV HOST_USER_NAME=${HOST_USER_NAME} \
    HOST_HOME=/home/${HOST_USER_NAME} \
    HOST_UID=${HOST_UID} \
    HOST_GID=${HOST_GID}

ENV WORKSPACE_PATH=${HOST_HOME}/app

RUN groupadd -g "${HOST_GID}" "${HOST_USER_NAME}" && \
    useradd --create-home --uid "${HOST_UID}" --gid "${HOST_GID}" "${HOST_USER_NAME}"

RUN apt update && apt upgrade -y
RUN apt install -y nsis lld llvm

USER "${HOST_USER_NAME}"
WORKDIR "${WORKSPACE_PATH}"

RUN rustup target add x86_64-pc-windows-msvc
RUN cargo install cargo-xwin

# BUILD WITH:
# Host shell: docker build --build-arg "HOST_USER_NAME=$(id -un)" --build-arg "HOST_UID=$(id -u)" --build-arg "HOST_GID=$(id -g)" -f Dockerfile.rust-linux-compile-windows-msvc -t rust/linux-compile-windows:msvc .

# RUN WITH:
# Host shell: docker run -it --rm -v $(pwd):/home/$(id -un)/app rust/linux-compile-windows:msvc
# Container shell: cd src-tauri && cargo tauri build --runner cargo-xwin --target x86_64-pc-windows-msvc

# CMD ["cargo", "build", "--runner", "cargo-xwin", "--target", "x86_64-pc-windows-msvc"]
CMD ["bash"]
