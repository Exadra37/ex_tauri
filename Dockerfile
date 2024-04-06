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

ARG DOCKER_BUILD_SCRIPTS_RELEASE=dev-wip

ARG CONTAINER_USER_NAME="developer"
ARG CONTAINER_UID="1000"
ARG CONTAINER_GID="1000"
ARG OH_MY_ZSH_THEME="amuse"

ARG LANGUAGE=""
ARG LANGUAGE_CODE="C"
ARG LOCALE_SEPARATOR=""
ARG COUNTRY_CODE=""
ARG ENCODING="UTF-8"
ARG LOCALE_STRING="${LANGUAGE_CODE}${LOCALE_SEPARATOR}${COUNTRY_CODE}"
ARG LOCALIZATION="${LOCALE_STRING}.${ENCODING}"
ARG DOCKER_BUILD_SCRIPTS_RELEASE=dev-wip

ENV LANG="${LOCALIZATION}" \
  LC_ALL="${LOCALIZATION}" \
  LANGUAGE="${LANGUAGE}" \
  DOCKER_BUILD="/docker-build" \
  WORKSPACE_PATH="/home/${CONTAINER_USER_NAME}/workspace" \
  CONTAINER_USER_NAME="${CONTAINER_USER_NAME}" \
  CONTAINER_HOME="/home/${CONTAINER_USER_NAME}" \
  CONTAINER_BIN_PATH="/home/${CONTAINER_USER_NAME}/bin" \
  CONTAINER_UID=${CONTAINER_UID} \
  CONTAINER_GID=${CONTAINER_GID}


###########################################
#  DEV ENVIRONMENT CUSTOMIZATION
###########################################

RUN \
  apt update && \
  apt -y upgrade && \
  apt -y -q install --no-install-recommends \
    ca-certificates \
    build-essential \
    ssh \
    less \
    nano \
    zsh \
    unzip \
    curl \
    git && \

  mkdir -p "${DOCKER_BUILD}" && \

  curl \
    -fsSl \
    -o archive.tar.gz \
    https://gitlab.com/exadra37-bash/docker/bash-scripts-for-docker-builds/-/archive/"${DOCKER_BUILD_SCRIPTS_RELEASE}"/bash-scripts-for-docker-builds-dev.tar.gz?path=scripts && \

  tar xf archive.tar.gz -C "${DOCKER_BUILD}" --strip 1 && \
  rm -vf archive.tar.gz && \

  "${DOCKER_BUILD}"/scripts/utils/debian/add-user-with-bin-folder.sh \
    "${CONTAINER_USER_NAME}" \
    "${CONTAINER_UID}" \
    "/usr/bin/zsh" \
    "${CONTAINER_BIN_PATH}" && \

  # "${DOCKER_BUILD}"/scripts/debian/install/locales.sh \
  #   "${LOCALIZATION}" \
  #   "${ENCODING}" && \

  "${DOCKER_BUILD}"/scripts/debian/install/inotify-tools.sh && \

  "${DOCKER_BUILD}"/scripts/debian/install/oh-my-zsh.sh \
    "${CONTAINER_HOME}" \
    "${OH_MY_ZSH_THEME}" && \

  "${DOCKER_BUILD}"/scripts/utils/create-workspace-dir.sh \
    "${WORKSPACE_PATH}" \
    "${CONTAINER_USER_NAME}"

RUN mkdir -p ~/.config ~/.local ~/.cache

RUN chown -R "${CONTAINER_USER_NAME}":"${CONTAINER_USER_NAME}" /home/"${CONTAINER_USER_NAME}"


##########################
# NODEJS STACK
##########################

RUN "${DOCKER_BUILD}"/scripts/nodejs/install.sh "${NODE_VERSION}"


##########################
# PHOENIX STACK
##########################

USER "${CONTAINER_USER_NAME}"
WORKDIR "${CONTAINER_HOME}"

RUN mix local.hex --force
RUN mkdir /home/"${CONTAINER_USER_NAME}"/.ssh
RUN ssh-keyscan -t rsa github.com >>  /home/"${CONTAINER_USER_NAME}"/.ssh/known_hosts
RUN ssh-keyscan -t rsa gitlab.com >> /home/"${CONTAINER_USER_NAME}"/.ssh/known_hosts
RUN "${DOCKER_BUILD}"/scripts/elixir/phoenix/install-from-git-branch.bash "${PHOENIX_VERSION}"


#########
# ZIG
#########

USER root
WORKDIR /opt

RUN curl https://ziglang.org/download/"${ZIG_VERSION}"/zig-linux-x86_64-"${ZIG_VERSION}".tar.xz -o zig.tar.xz
RUN tar -xf zig.tar.xz
RUN mv zig-linux-x86_64-"${ZIG_VERSION}" /opt/zig-"${ZIG_VERSION}"

ENV PATH=/opt/zig-"${ZIG_VERSION}":$PATH



########################
# TAURI RUST STACK
########################

USER root
WORKDIR /

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

USER "${CONTAINER_USER_NAME}"
WORKDIR "${CONTAINER_HOME}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain=${RUST_VERSION} -y
ENV PATH="~/.cargo/bin:$PATH"
RUN bash -c "cargo --version"
RUN bash -c "cargo install tauri-cli"
RUN bash -c "cargo install create-tauri-app"
RUN bash -c "cargo install -f cross"

# @error Strip call failed: /tmp/appimage_*: Unable to recognise the format of the input file `example-desktop.AppDir/usr/lib/librsvg-2.so'
# @link https://github.com/tauri-apps/tauri/issues/8929#issuecomment-1956338150
ENV NO_STRIP=true

# @error Cannot mount AppImage, please check your FUSE setup.
# @link https://github.com/AppImage/AppImageKit/issues/912#issuecomment-528669441
ENV APPIMAGE_EXTRACT_AND_RUN=1


########################
# START - WORKSPACE
########################

WORKDIR "${WORKSPACE_PATH}"

CMD ["zsh"]
