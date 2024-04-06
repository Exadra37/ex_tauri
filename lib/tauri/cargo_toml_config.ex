defmodule ExTauri.Tauri.CargoTomlConfig do

	require Logger

	# Override Cargo.toml to use app_name and set proper crates so they are not dependent on folders
	def override() do
	  path = [File.cwd!(), "src-tauri", "Cargo.toml"] |> Path.join()

	  Logger.warning("Overriding cargo toml config at: " <> path)

	  cargo_toml_config = build_cargo_toml_config()

	  path
	  |> File.write!(cargo_toml_config)
	end

	defp build_cargo_toml_config() do
	  app_name = ExTauri.get_config!(:ex_tauri, :app_name)
	  package_name = build_package_name()
	  version = ExTauri.get_config(:ex_tauri, :app_version, "0.1.0")
	  description = ExTauri.get_config(:ex_tauri, :app_description, "A Phoenix Tauri App")
	  authors = ExTauri.get_config(:ex_tauri, :app_authors, [app_name]) |> Enum.join("\",\"")
	  app_license = ExTauri.get_config(:ex_tauri, :app_license, "Proprietary")
	  app_homepage = ExTauri.get_config(:ex_tauri, :app_homepage, "example.com")
	  app_repository = ExTauri.get_config(:ex_tauri, :app_repository, "example.com")
	  rust_edition = ExTauri.get_config(:ex_tauri, :rust_edition, "2021")

	  [_, rust_version | _rest ] = System.cmd("rustc", ["--version"])
	    |> elem(0)
	    |> String.split(" ")

	  """
	  [package]
	  name = "#{package_name}"
	  version = "#{version}"
	  description = "#{description}"
	  authors = ["#{authors}"]
	  license = "#{app_license}"
	  homepage = "#{app_homepage}"
	  repository = "#{app_repository}"
	  default-run = "#{package_name}"
	  edition = "#{rust_edition}"
	  rust-version = "#{rust_version}"

	  [build-dependencies]
	  tauri-build = { version = "1", features = [] }

	  [dependencies]
	  serde_json = "1.0"
	  serde = { version = "1.0", features = ["derive"] }
	  tauri = { version = "1", features = [ "shell-sidecar"] }
	  fix-path-env = { git = "https://github.com/tauri-apps/fix-path-env-rs" }

	  [features]
	  # by default Tauri runs in production mode
	  # when `tauri dev` runs it is executed with `cargo run --no-default-features` if `devPath` is an URL
	  default = [ "custom-protocol" ]

	  # this feature is used for production builds where `devPath` points to the filesystem
	  # DO NOT remove this
	  custom-protocol = [ "tauri/custom-protocol" ]
	  """
	end

	defp build_package_name() do
	  ExTauri.get_config!(:ex_tauri, :app_name)
	  |> String.replace("\s", "")
	  |> Macro.underscore()
	end

end
