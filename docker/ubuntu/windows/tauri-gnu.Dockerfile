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

RUN apt update && apt upgrade -y
RUN apt install -y g++-mingw-w64-x86-64 

# @link https://tauri.app/v1/guides/getting-started/prerequisites#setting-up-linux
RUN apt -y install --no-install-recommends libwebkit2gtk-4.0-dev
RUN apt -y install --no-install-recommends curl
RUN apt -y install --no-install-recommends wget
RUN apt -y install --no-install-recommends build-essential
RUN apt -y install --no-install-recommends file
RUN apt -y install --no-install-recommends libssl-dev
RUN apt -y install --no-install-recommends libgtk-3-dev
RUN apt -y install --no-install-recommends libayatana-appindicator3-dev
RUN apt -y install --no-install-recommends librsvg2-dev

RUN apt -y install --no-install-recommends zsh

# RUN apt -y install --no-install-recommends nsis
# RUN apt -y install --no-install-recommends lld
# RUN apt -y install --no-install-recommends llvm

USER "${HOST_USER_NAME}"
WORKDIR "${WORKSPACE_PATH}"

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# RUN sed -i "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"${OH_MY_ZSH_THEME}\"/g" "${HOST_HOME}"/.zshrc

RUN rustup target add x86_64-pc-windows-gnu 
RUN rustup toolchain install stable-x86_64-pc-windows-gnu 
RUN cargo install tauri-cli

# BUILD WITH:
# Host shell: docker build --build-arg "HOST_USER_NAME=$(id -un)" --build-arg "HOST_UID=$(id -u)" --build-arg "HOST_GID=$(id -g)" -f docker/linux/windows/tauri-gnu.Dockerfile -t tauri/linux-compile-windows:gnu .

# RUN WITH:
# Host shell: docker run -it --rm -v $(pwd):/home/$(id -un)/app tauri/linux-compile-windows:gnu
# Container shell: cd example/src-tauri && cargo tauri build --target x86_64-pc-windows-gnu

# CMD ["cargo", "tauri", "build", "--target", "x86_64-pc-windows-gnu"]
CMD ["zsh"]
