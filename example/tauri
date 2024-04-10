#!/bin/sh

set -eu

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

	for input in "${@}"; do
    case "${input}" in
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

			help )
				Show_Help
				exit $?
				;;

    esac
  done

  Show_Help
}


Main "${@}"
