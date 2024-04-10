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
# @link Github action: https://github.com/tauri-apps/tauri-action
# @link Windows: https://github.com/tauri-apps/tauri/issues/1114
# @link https://jamwaffles.github.io/rust/2019/02/17/rust-cross-compile-linux-to-macos.html
# @link https://github.com/dockcross/dockcross
# @link https://github.com/cross-rs/cross-toolchains?tab=readme-ov-file#apple-targets
# @link https://github.com/tpoechtrager/osxcross
# @link https://tauri.app/v1/guides/building/cross-platform/#experimental-build-windows-apps-on-linux-and-macos
#


Show_Help() {
	echo "
	Bash wrapper to build an App with Tauri and Phoenix Live View

	./compile <command>

	Assets:
	$ ./compile assets

	Install:
	$ ./compile install

	Build:
	$ ./compile build

	Rebuild:
	$ ./compile rebuild

	Cleanup:
	$ ./compile cleanup
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

Docker_Build() {
	sudo docker build \
		--progress plain \
		--build-arg "OS_TAG=${OS_TAG}" \
		--build-arg "HOST_UID=$(id -u)" \
		--build-arg "HOST_GID=$(id -g)" \
		--build-arg "HOST_USER_NAME=$(id -un)" \
		--tag "${CONTAINER_IMAGE}" \
		--file "${DOCKERFILE_PATH}" \
		"${PWD}"
}

Docker_Run() {
	# local _burrito_cache_dir=.cache/burrito_file_cache
	# local _local_burrito_cache_dir=.local/.cache/burrito_file_cache
	# mkdir -p "${_local_burrito_cache_dir}"
	# --volume "${_local_burrito_cache_dir}":$PWD/"${_burrito_cache_dir}" \

	sudo docker run \
		-it \
		--rm \
		--name "${CONTAINER_NAME}" \
		--publish 4800:4000 \
		--workdir $PWD \
		--volume $PWD:$PWD \
		"${CONTAINER_IMAGE}" "${COMMAND}" "${@}"
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
	local OS_NAME=ubuntu
	local OS_VERSION=22.04
	local OS_TAG=${OS_NAME}_${OS_VERSION}
	local CONTAINER_IMAGE=exadra37/ex_tauri:${OS_TAG}

	local TARGET_PLATFORM=linux
	local VENDOR=tauri
	local COMPILER_TYPE=gnu

	# from `/home/user/project/.app/acme` we will get `.app_acme`
	local _dir=${PWD%/*}
	local _name="${_dir##*/}_${PWD##*/}"

	# from .app_acme we get app_acme
	local CONTAINER_NAME="${_name#"${_name%%[!.]*}"}"

	local COMMAND="cargo ${@##*/}"


	for input in "${@}"; do
    case "${input}" in

    	--os-name )
				shift 1
				OS_NAME="${1:? Missing value for the vendor, eg. ubuntu}"
				;;

			--target-platform )
				shift 1
				TARGET_PLATFORM="${1:? Missing value for the vendor, eg. windows}"
				;;

			--vendor )
				shift 1
				VENDOR="${1:? Missing value for the vendor, eg. tauri}"
				shift 1
				;;

			--compiler-type )
				shift 1
				COMPILER_TYPE="${1:? Missing value for the compiler type, eg. gnu}"
				;;

			docker-build )
				shift 1
				local DOCKERFILE_PATH="${1:-docker/${OS_NAME}/${TARGET_PLATFORM}/${VENDOR}-${COMPILER_TYPE}.Dockerfile}"

				Docker_Build "${@}"
				exit $?
				;;

			shell )
				shift 1
				COMMAND=${1:-zsh}
				Docker_Run "${@}"
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

  Show_Help
}


Main "${@}"
