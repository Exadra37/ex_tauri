FROM hexpm/elixir:1.16.2-erlang-26.2.3-ubuntu-jammy-20240125

ARG PHOENIX_VERSION=1.7.11
ENV DOCKER_PHOENIX_VERSION=${PHOENIX_VERSION}

ARG RUST_VERSION=1.77.1
ENV DOCKER_RUST_VERSION=${RUST_VERSION}

# ZIG is required by Burrito to package Elixir as a standalone binary
ARG ZIG_VERSION=0.11.0
ENV DOCKER_ZIG_VERSION=0.11.0

ARG NODE_VERSION=20
ENV DOCKER_NODE_VERSION=${NODE_VERSION}

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

RUN apt update
RUN apt -y install --no-install-recommends inotify-tools
RUN apt -y install --no-install-recommends build-essential
RUN apt -y install --no-install-recommends curl


##############
# HOST USER
##############

RUN groupadd -g "${HOST_GID}" "${HOST_USER_NAME}" && \
    useradd --create-home --uid "${HOST_UID}" --gid "${HOST_GID}" "${HOST_USER_NAME}"
RUN mkdir -p "${HOST_HOME}"/.config "${HOST_HOME}"/.local/{bin,share} "${HOST_HOME}"/.cache
RUN chown -R "${HOST_USER_NAME}":"${HOST_USER_NAME}" "${HOST_HOME}"


###############
#  OH MY ZSH
###############

RUN apt -y install --no-install-recommends git
RUN apt -y install --no-install-recommends zsh

USER "${HOST_USER_NAME}"
WORKDIR "${HOST_HOME}"

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN sed -i "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"${OH_MY_ZSH_THEME}\"/g" "${HOST_HOME}"/.zshrc


######################
# ZIG - Burrito dep
######################

USER root
WORKDIR /

RUN curl https://ziglang.org/download/"${ZIG_VERSION}"/zig-linux-x86_64-"${ZIG_VERSION}".tar.xz -o zig.tar.xz
RUN tar -xf zig.tar.xz
RUN mv zig-linux-x86_64-"${ZIG_VERSION}" /opt/zig-"${ZIG_VERSION}"

ENV PATH=/opt/zig-"${ZIG_VERSION}":$PATH


######################
# Burrito deps
######################

# Required when building for Windows
RUN apt -y install --no-install-recommends p7zip-full


###############################
# NODEJS STACK - Phoenix dep
###############################

RUN curl -sL https://deb.nodesource.com/setup_"${NODE_VERSION}".x | sh -
RUN apt update
RUN apt install -y --no-install-recommends nodejs


##########################
# PHOENIX STACK
##########################

USER "${HOST_USER_NAME}"
WORKDIR "${HOST_HOME}"

# installs the package manager
RUN mix local.hex --force

# installs rebar and rebar3
RUN mix local.rebar --force
ENV PATH="${HOST_HOME}"/.mix:${PATH}

# COMPILE AND INSTALL PHOENIX FROM SOURCE
RUN git clone --depth 1 --branch "v${PHOENIX_VERSION}" https://github.com/phoenixframework/phoenix.git

WORKDIR "${HOST_HOME}/phoenix/installer"
RUN MIX_ENV=prod mix do archive.build, archive.install --force
RUN cd ../../ && rm -rf phoenix
RUN mix phx.new --version


########################
# TAURI RUST STACK
########################

USER root
WORKDIR /

# @link https://tauri.app/v1/guides/getting-started/prerequisites#setting-up-linux
RUN apt -y install --no-install-recommends libwebkit2gtk-4.0-dev
# RUN apt -y install --no-install-recommends curl
RUN apt -y install --no-install-recommends wget
RUN apt -y install --no-install-recommends build-essential
RUN apt -y install --no-install-recommends file
RUN apt -y install --no-install-recommends libssl-dev
RUN apt -y install --no-install-recommends libgtk-3-dev
RUN apt -y install --no-install-recommends libayatana-appindicator3-dev
RUN apt -y install --no-install-recommends librsvg2-dev

USER "${HOST_USER_NAME}"
WORKDIR "${HOST_HOME}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain=${RUST_VERSION} -y
ENV PATH="~/.cargo/bin:$PATH"
RUN bash -c "cargo --version"
RUN bash -c "cargo install tauri-cli"
RUN bash -c "cargo install create-tauri-app"
RUN bash -c "cargo install -f cross"
RUN bash -c "rustup target add x86_64-apple-darwin"
RUN bash -c "rustup target add x86_64-pc-windows-gnu"

# @error Strip call failed: /tmp/appimage_*: Unable to recognise the format of the input file `example-desktop.AppDir/usr/lib/librsvg-2.so'
# @link https://github.com/tauri-apps/tauri/issues/8929#issuecomment-1956338150
ENV NO_STRIP=true

# @error Cannot mount AppImage, please check your FUSE setup.
# @link https://github.com/AppImage/AppImageKit/issues/912#issuecomment-528669441
ENV APPIMAGE_EXTRACT_AND_RUN=1

USER root
WORKDIR /

# @link https://github.com/tauri-apps/tauri/issues/6746#issuecomment-1516059273
RUN apt -y install --no-install-recommends gcc-mingw-w64-x86-64

# tauri dep to compile windows
RUN apt -y install --no-install-recommends nsis

RUN apt -y install --no-install-recommends g++-mingw-w64-x86-64
RUN apt -y install --no-install-recommends lld llvm

# trying to fix macos error when building
# RUN apt -y install --no-install-recommends clang


########################
# START - WORKSPACE
########################

USER "${HOST_USER_NAME}"
WORKDIR "${WORKSPACE_PATH}"

# tauri dep to compile windows
RUN bash -c "rustup target add x86_64-pc-windows-msvc"
RUN bash -c "cargo install cargo-xwin"
RUN bash -c "rustup toolchain install stable-x86_64-pc-windows-gnu"

USER root
WORKDIR /

RUN apt -y install --no-install-recommends clang
RUN apt -y install --no-install-recommends g++


USER "${HOST_USER_NAME}"
WORKDIR "${WORKSPACE_PATH}"

CMD ["zsh"]
