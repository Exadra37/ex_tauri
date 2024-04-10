defmodule ExTauri do

  use Application
  require Logger

  alias  ExTauri.Tauri

  @doc false
  def start(_, _) do
    unless Application.get_env(:ex_tauri, :version) do
      Logger.warning("""
      tauri version is not configured. Please set it in your config files:

          config :ex_tauri, :version, "#{latest_version()}"
      """)
    end

    Supervisor.start_link([], strategy: :one_for_one)
  end

  @doc """
  Returns a :key from the :app configuration. If doesn't exist `default` is returned.
  """
  defdelegate get_config(app, key, default \\ nil), to: ExTauri.AppConfig, as: :get

  @doc """
  Returns a :key from the :app configuration. If doesn't exist it will raise.
  """
  defdelegate get_config!(app, key), to: ExTauri.AppConfig, as: :get!

  @doc """
  Returns a :key from the `mix.exs` :project configuration. If doesn't exist `default` is returned.
  """
  defdelegate get_project_config(key, default \\ nil), to: ExTauri.AppConfig, as: :get_project

  @doc """
  Returns a :key from the `mix.exs` :project configuration. If doesn't exist it will raise.
  """
  defdelegate get_project_config!(key), to: ExTauri.AppConfig, as: :get_project!

  @doc """
  Returns the latest version of tauri available.
  """
  defdelegate latest_version, to: Tauri.Install

  @doc """
  Install Tauri in the Elixir project at `src-tauri`.
  """
  defdelegate install(extra_args \\ []), to: Tauri.Install

  @doc """
  Returns the path to the executable.

  The executable may not be available if it was not yet installed.
  """
  defdelegate installation_path(), to: Tauri.Install

  @doc """
  Installs, if not available, and then runs `tailwind`.

  Returns the same as `bundle_release/2`.
  """
  def install_and_run(args) do
    unless File.exists?(installation_path()) do
      install(args)
    end

    bundle_release(args)
  end

  @doc """
  Bundles each release configures in your `mix.exs` as a Tauri release.

  The given args will be appended to the configured args.
  The task output will be streamed directly to stdio.
  It returns the status of the underlying call.
  """
  defdelegate bundle_release(args), to: Tauri.BundleRelease, as: :build

  @doc """
  When bundling a release we may want to update the Tauri configuration based on the `:ex_tauri`
  configuration at your `config/config.exs`:

  * :app_name
  * :window_title
  * :fullscreen
  * :height
  * :height
  * :resize

  For example, to update the version.
  """
  defdelegate upsert_tauri_json_config(burrito_bin_path), to: Tauri.JsonConfig, as: :upsert


  defdelegate override_cargo_toml_config(), to: Tauri.CargoTomlConfig, as: :override

  defdelegate override_main_src_code(release_name), to: Tauri.RustMainSourceCode, as: :override
end
