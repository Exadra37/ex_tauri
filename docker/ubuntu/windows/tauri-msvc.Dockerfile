FROM rust:latest

ARG OH_MY_ZSH_THEME="amuse"
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

# @link https://tauri.app/v1/guides/building/cross-platform/#experimental-build-windows-apps-on-linux-and-macos
RUN apt update && apt upgrade -y
RUN apt -y install --no-install-recommends nsis
RUN apt -y install --no-install-recommends lld
# RUN apt -y install --no-install-recommends llvm

# @link https://tauri.app/v1/guides/getting-started/prerequisites#setting-up-linux
# RUN apt -y install --no-install-recommends libwebkit2gtk-4.0-dev
# RUN apt -y install --no-install-recommends curl
# RUN apt -y install --no-install-recommends wget
# RUN apt -y install --no-install-recommends build-essential
# RUN apt -y install --no-install-recommends file
# RUN apt -y install --no-install-recommends libssl-dev
# RUN apt -y install --no-install-recommends libgtk-3-dev
# RUN apt -y install --no-install-recommends libayatana-appindicator3-dev
# RUN apt -y install --no-install-recommends librsvg2-dev

# Oh-My-Zsh
RUN apt -y install --no-install-recommends zsh

USER "${HOST_USER_NAME}"
WORKDIR "${HOST_HOME}"

# Oh-My-Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# RUN sed -i "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"${OH_MY_ZSH_THEME}\"/g" "${HOST_HOME}"/.zshrc

# @link https://tauri.app/v1/guides/building/cross-platform/#experimental-build-windows-apps-on-linux-and-macos
RUN rustup target add x86_64-pc-windows-msvc
# RUN cargo install cargo-xwin

# @link https://github.com/tauri-apps/tauri/pull/5788
RUN cargo install xwin
RUN xwin --accept-license splat --output ~/xwin
RUN mkdir -p .cargo
RUN echo "[target.x86_64-pc-windows-msvc]" > ~/.cargo/config.toml
RUN echo "linker = \"lld\""
RUN echo "rustflags = [" >> ~/.cargo/config.toml
RUN echo "  \"-Lnative=/home/${HOST_USER_NAME}/xwin/crt/lib/x86_64\"," >> ~/.cargo/config.toml
RUN echo "  \"-Lnative=/home/${HOST_USER_NAME}/xwin/sdk/lib/um/x86_64\"," >> ~/.cargo/config.toml
RUN echo "  \"-Lnative=/home/${HOST_USER_NAME}/xwin/sdk/lib/ucrt/x86_64\"" >> ~/.cargo/config.toml
RUN echo "]" >> ~/.cargo/config.toml

RUN cargo install tauri-cli

# USER root

# RUN apt -y install --no-install-recommends clang
# RUN apt -y install --no-install-recommends binutils-mingw-w64
# RUN apt -y install --no-install-recommends gcc-mingw-w64-x86-64


USER "${HOST_USER_NAME}"
WORKDIR "${WORKSPACE_PATH}"

# BUILD WITH:
# Host shell: docker build --build-arg "HOST_USER_NAME=$(id -un)" --build-arg "HOST_UID=$(id -u)" --build-arg "HOST_GID=$(id -g)" -f docker/linux/windows/tauri-msvc.Dockerfile -t tauri/linux-compile-windows:msvc .

# RUN WITH:
# Host shell: docker run -it --rm -v $(pwd):/home/$(id -un)/app tauri/linux-compile-windows:msvc
# Container shell: cd example/src-tauri && cargo tauri build --target x86_64-pc-windows-msvc

# CMD ["cargo", "build", "--runner", "cargo-xwin", "--target", "x86_64-pc-windows-msvc"]
CMD ["zsh"]
