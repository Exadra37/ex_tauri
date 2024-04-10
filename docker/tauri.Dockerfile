ARG OS_TAG
ARG CROSS_COMPILE_ARCH

FROM exadra37/cross:${OS_TAG}_${CROSS_COMPILE_ARCH}

# @link https://github.com/cross-rs/cross/blob/main/docs/config_file.md#builddockerfile
# FROM ghcr.io/cross-rs/aarch64-unknown-linux-gnu:latest
# FROM ghcr.io/cross-rs/${CROSS_COMPILE_ARCH}:latest

# RUN dpkg --add-architecture $CROSS_DEB_ARCH && \
#     apt-get update && \
#     apt-get install --assume-yes libfoo:$CROSS_DEB_ARCH

# ARG PHOENIX_VERSION=1.7.11
# ENV DOCKER_PHOENIX_VERSION=${PHOENIX_VERSION}

ARG RUST_VERSION=1.77.1
ENV DOCKER_RUST_VERSION=${RUST_VERSION}

# ZIG is required by Burrito to package Elixir as a standalone binary
# ARG ZIG_VERSION=0.11.0
# ENV DOCKER_ZIG_VERSION=0.11.0

# ARG NODE_VERSION=20
# ENV DOCKER_NODE_VERSION=${NODE_VERSION}

ARG HOST_USER_NAME="developer"
ARG HOST_UID="1000"
ARG HOST_GID="1000"
ARG OH_MY_ZSH_THEME="amuse"

ENV HOST_USER_NAME=${HOST_USER_NAME} \
    HOST_HOME=/home/${HOST_USER_NAME} \
    HOST_UID=${HOST_UID} \
    HOST_GID=${HOST_GID}

ENV WORKSPACE_PATH=${HOST_HOME}/workspace

USER root
WORKDIR /

# Creating the USER
RUN groupadd -g "${HOST_GID}" "${HOST_USER_NAME}" && \
    useradd --create-home --uid "${HOST_UID}" --gid "${HOST_GID}" "${HOST_USER_NAME}"


##########################
# NODEJS STACK
##########################

# RUN "${DOCKER_BUILD}"/scripts/nodejs/install.sh "${NODE_VERSION}"


##########################
# PHOENIX STACK
##########################

# USER "${HOST_USER_NAME}"
# WORKDIR "${HOST_HOME}"

# RUN mix local.hex --force
# RUN mkdir /home/"${HOST_USER_NAME}"/.ssh
# RUN ssh-keyscan -t rsa github.com >>  /home/"${HOST_USER_NAME}"/.ssh/known_hosts
# RUN ssh-keyscan -t rsa gitlab.com >> /home/"${HOST_USER_NAME}"/.ssh/known_hosts
# RUN "${DOCKER_BUILD}"/scripts/elixir/phoenix/install-from-git-branch.bash "${PHOENIX_VERSION}"


#########
# ZIG
#########

# USER root
# WORKDIR /opt

# RUN curl https://ziglang.org/download/"${ZIG_VERSION}"/zig-linux-x86_64-"${ZIG_VERSION}".tar.xz -o zig.tar.xz
# RUN tar -xf zig.tar.xz
# RUN mv zig-linux-x86_64-"${ZIG_VERSION}" /opt/zig-"${ZIG_VERSION}"

# ENV PATH=/opt/zig-"${ZIG_VERSION}":$PATH



########################
# TAURI RUST STACK
########################

# USER root
# WORKDIR /

# @link https://tauri.app/v1/guides/getting-started/prerequisites#setting-up-linux
RUN apt update
RUN	apt -y install --no-install-recommends libwebkit2gtk-4.0-dev
RUN	apt -y install --no-install-recommends build-essential
RUN	apt -y install --no-install-recommends curl
RUN	apt -y install --no-install-recommends wget
RUN	apt -y install --no-install-recommends file
RUN	apt -y install --no-install-recommends libssl-dev
RUN	apt -y install --no-install-recommends libgtk-3-dev
RUN	apt -y install --no-install-recommends libayatana-appindicator3-dev
RUN	apt -y install --no-install-recommends librsvg2-dev

RUN apt -y install --no-install-recommends zsh
RUN apt -y install --no-install-recommends clang

USER "${HOST_USER_NAME}"
WORKDIR "${HOST_HOME}"


RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# RUN sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain=${RUST_VERSION} -y
ENV PATH="~/.cargo/bin:$PATH"
RUN bash -c "cargo --version"
RUN bash -c "cargo install tauri-cli"
RUN bash -c "cargo install create-tauri-app"
RUN bash -c "cargo install -f cross"
RUN bash -c "rustup target add x86_64-apple-darwin"
RUN bash -c "rustup target add aarch64-apple-darwin"

# @error Strip call failed: /tmp/appimage_*: Unable to recognise the format of the input file `example-desktop.AppDir/usr/lib/librsvg-2.so'
# @link https://github.com/tauri-apps/tauri/issues/8929#issuecomment-1956338150
ENV NO_STRIP=true

# @error Cannot mount AppImage, please check your FUSE setup.
# @link https://github.com/AppImage/AppImageKit/issues/912#issuecomment-528669441
ENV APPIMAGE_EXTRACT_AND_RUN=1


########################
# START - WORKSPACE
########################

WORKDIR "${HOST_HOME}/workspace"

CMD ["zsh"]
