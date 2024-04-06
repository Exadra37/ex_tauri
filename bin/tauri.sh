#!/bin/sh

set -eu

#######################
# Tauri App Examples
#######################
#
# @link https://github.com/tauri-apps/awesome-tauri
#

##############################
# Phoenix Apps to Tauririze
##############################
#
# @link https://github.com/chrismccord/todo_trek (https://phoenixframework.org/blog/phoenix-liveview-0.19-released)
# @link https://github.com/fly-apps/live_beats (https://fly.io/blog/livebeats/)
#


##################
# Cross Compile
##################
#
# @link https://jamwaffles.github.io/rust/2019/02/17/rust-cross-compile-linux-to-macos.html
# @link https://github.com/dockcross/dockcross
# @link https://github.com/cross-rs/cross-toolchains?tab=readme-ov-file#apple-targets
# @link https://github.com/tpoechtrager/osxcross
# @link https://tauri.app/v1/guides/building/cross-platform/#experimental-build-windows-apps-on-linux-and-macos
#




Show_Help() {
	echo "
	Bash wrapper to build an App with Tauri and Phoenix Live View

	./tauri <command>

	Assets:
	$ ./tauri assets

	Install:
	$ ./tauri install

	Build:
	$ ./tauri build

	Rebuild:
	$ ./tauri rebuild

	Cleanup:
	$ ./tauri cleanup
	"

	Show_Alert
}

Show_Alert() {
	echo "
	*** ALERT ***

	On the first run, the app image is installed on your machine, and new installs need to bump the version.

	If you forget to do so, you will use the old binary, not the one you built now ;)

	Find the path where the binary is installed with one of:

	$ burrito_out/desktop-x86_64-unknown-linux-gnu maintenance directory

	$ burrito_out/desktop-aarch64-apple-darwin maintenance directory

	"
}

Docker_Build_Cross() {
	sudo docker build \
		--progress plain \
		--tag "${CROSS_CONTAINER_IMAGE}_${CROSS_COMPILE_ARCH}" \
		--file "${PWD}/docker/Dockerfile.${CROSS_COMPILE_ARCH}" \
		"${PWD}/docker"
}

Docker_Build_Tauri() {
	sudo docker build \
		--progress plain \
		--build-arg "OS_TAG=${OS_TAG}" \
		--build-arg "HOST_UID=$(id -u)" \
		--build-arg "HOST_GID=$(id -g)" \
		--build-arg "HOST_USER_NAME=$(id -un)" \
		--build-arg "CROSS_COMPILE_ARCH=${CROSS_COMPILE_ARCH}" \
		--tag "${TAURI_CONTAINER_IMAGE}_${CROSS_COMPILE_ARCH}" \
		--file "Dockerfile.tauri" \
		"${PWD}"
}

Docker_Run_Tauri() {
		sudo docker run \
			-it \
			--rm \
			--name "${CONTAINER_NAME}" \
			--publish 4400:4000 \
			--volume $PWD:/home/$(id -un)/workspace \
			"${TAURI_CONTAINER_IMAGE}_${CROSS_COMPILE_ARCH}" "${COMMAND}" "${@}"
}

Assets() {
	mix deps.get
	mix assets.deploy
}

Build() {
	Assets

	mix deps.get --only prod
	MIX_ENV=prod mix ex_tauri build
}

Cleanup() {
	rm -rvf deps
	rm -rvf _build/prod
	rm -rvf burrito_out
	rm -rvf src-tauri/target
	rm -rvf ~/.local/share/.burrito

	MIX_ENV=prod mix deps.get
	MIX_ENV=prod mix compile
}

Install() {
	MIX_ENV=prod mix ex_tauri.install
}

Rebuild() {
	Cleanup
	Install
	Build
}

Main() {

	local OS_VERSION=22.04
	local OS_TAG=ubuntu_${OS_VERSION}

	local CROSS_CONTAINER_IMAGE=exadra37/cross:${OS_TAG}
	local TAURI_CONTAINER_IMAGE=exadra37/ex_tauri:${OS_TAG}

	# from `/home/user/project/app/acme` we will get `app_acme`
	local _dir=${PWD%/*}
	local CONTAINER_NAME="${_dir##*/}_${PWD##*/}"

	local COMMAND="cargo ${0##*/}"

	local CROSS_COMPILE_ARCH=aarch64-unknown-linux-gnu

	for input in "${@}"; do
    case "${input}" in

    	docker-build )
				shift 1
				Docker_Build_Cross
				Docker_Build_Tauri "${@}"
				exit $?
				;;

			shell )
				shift 1
				COMMAND=${1:-zsh}
				Docker_Run_Tauri
				exit $?
				;;

    	assets )
				Assets
				exit $?
				;;

    	build )
				Build
				Show_Alert
				exit $?
				;;

    	cleanup )
				Cleanup
				exit $?
				;;

			install )
				Install
				exit $?
				;;

			rebuild )
				Rebuild
				Show_Alert
				exit $?
				;;

			--help )
				Show_Help
				exit $?
				;;

    esac
  done

  Docker_Run_Tauri "${@}"
}


Main "${@}"
