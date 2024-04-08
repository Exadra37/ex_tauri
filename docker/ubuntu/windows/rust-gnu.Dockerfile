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
RUN apt install -y g++-mingw-w64-x86-64

USER "${HOST_USER_NAME}"
WORKDIR "${WORKSPACE_PATH}"

RUN rustup target add x86_64-pc-windows-gnu 
RUN rustup toolchain install stable-x86_64-pc-windows-gnu 

# BUILD WITH:
# Host shell: docker build --build-arg "HOST_USER_NAME=$(id -un)" --build-arg "HOST_UID=$(id -u)" --build-arg "HOST_GID=$(id -g)" -f Dockerfile.tauri-windows-gnu -t tauri/windows:gnu .

# RUN WITH:
# Host shell: docker run -it --rm -v $(pwd):/home/$(id -un)/app tauri/windows:gnu
# Container shell: cd src-tauri && cargo build --target x86_64-pc-windows-gnu

# CMD ["cargo", "build", "--target", "x86_64-pc-windows-gnu"]
CMD ["bash"]
