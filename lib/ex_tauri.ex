defmodule ExTauri do
  @latest_version "1.5.11"

  use Application
  require Logger
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
  Returns the latest version of tauri available.
  """
  def latest_version, do: @latest_version

  def install(extra_args \\ []) do
    app_name = get_app_name()
    window_title = Application.get_env(:ex_tauri, :window_title, app_name)
    scheme = Application.get_env(:ex_tauri, :scheme) || "http"
    host = Application.get_env(:ex_tauri, :host) || raise "Expected :host to be configured"
    port = Application.get_env(:ex_tauri, :port) || raise "Expected :port to be configured"
    version = Application.get_env(:ex_tauri, :cli_version) || latest_version()
    fullscreen = Application.get_env(:ex_tauri, :fullscreen, false)
    height = Application.get_env(:ex_tauri, :height, 600)
    width = Application.get_env(:ex_tauri, :width, 800)
    resize = Application.get_env(:ex_tauri, :resize, true)
    installation_path = installation_path()
    File.mkdir_p!(installation_path)

    opts = [
      cd: installation_path,
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ]

    System.cmd("cargo", ["install", "tauri-cli@#{version}", "--root", "."], opts)

    args =
      [
        "init",
        "--app-name",
        app_name |> String.replace("\s", "") |> Macro.underscore(),
        "--window-title",
        window_title,
        "--dev-path",
        "#{scheme}://#{host}:#{port}",
        "--dist-dir",
        "#{scheme}://#{host}:#{port}",
        "--directory",
        File.cwd!(),
        "--tauri-path",
        File.cwd!(),
        "--before-dev-command",
        "",
        "--before-build-command",
        ""
      ] ++ extra_args

    opts = [
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ]

    res =
      Path.join([installation_path, "bin", "cargo-tauri"])
      |> System.cmd(args, opts)
      |> elem(1)

    case res do
      0 -> :ok
      _ -> raise "tauri unable to install. exited with status #{res}"
    end

    # Override Cargo.toml to use app_name and set proper crates so they are not dependent on folders
    path = Path.join([File.cwd!(), "src-tauri", "Cargo.toml"])
    File.write!(path, cargo_toml(app_name))

    # Override main.rs to set proper startup sequence
    path = Path.join([File.cwd!(), "src-tauri", "src", "main.rs"])
    File.write!(path, main_src(host, port))

    # TODO remove this when possible, for some reason it's failing at the moment
    File.cp!(
      Path.join([File.cwd!(), "src-tauri", "build.rs"]),
      Path.join([File.cwd!(), "src-tauri", "src", "build.rs"])
    )

    # File.cp!(
    #   Path.join([File.cwd!(), "bin", "tauri.sh"]),
    #   Path.join([File.cwd!(), "tauri"])
    # )

    # The build name needs to be unique, otherwise any app built by burrito will always
    # be installed in the same path on the target
    release_name = build_release_name()
    burrito_output = "../burrito_out/#{release_name}"

    # Add side car and required configuration to tauri.conf.json
    Path.join([File.cwd!(), "src-tauri", "tauri.conf.json"])
    |> File.read!()
    |> Jason.decode!()
    |> then(fn content ->
      content
      |> put_in(["package", "productName"], app_name)
      |> put_in(["tauri", "bundle", "externalBin"], [burrito_output])
      |> put_in(
        ["tauri", "bundle", "identifier"],
        "you.app.#{app_name |> String.replace("\s", "") |> Macro.underscore() |> String.replace("_", "-")}"
      )
      |> put_in(["tauri", "allowlist"], %{
        shell: %{
          sidecar: true,
          scope: [%{name: burrito_output, sidecar: true, args: ["start"]}]
        }
      })
      |> put_in(["tauri", "windows"], [
        %{
          title: window_title,
          fullscreen: fullscreen,
          width: width,
          height: height,
          resizable: resize
        }
      ])
    end)
    |> Jason.encode!(pretty: true)
    |> then(&File.write!(Path.join([File.cwd!(), "src-tauri", "tauri.conf.json"]), &1))
  end

  @doc """
  Returns the path to the executable.

  The executable may not be available if it was not yet installed.
  """
  def installation_path do
    Application.get_env(:ex_tauri, :path) ||
      if Code.ensure_loaded?(Mix.Project) do
        Path.join(Path.dirname(Mix.Project.build_path()), "_tauri")
      else
        Path.expand("_build/_tauri")
      end
  end

  @doc """
  Installs, if not available, and then runs `tailwind`.

  Returns the same as `run/2`.
  """
  def install_and_run(args) do
    unless File.exists?(installation_path()) do
      install(args)
    end

    run(args)
  end

  @doc """
  Runs the given command with `args`.

  The given args will be appended to the configured args.
  The task output will be streamed directly to stdio. It
  returns the status of the underlying call.
  """
  def run(args) when is_list(args) do
    wrap()

    # Set proper environment variables for tauri
    System.put_env("TAURI_SKIP_DEVSERVER_CHECK", "true")

    opts = [
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ]

    {_, 0} =
      [installation_path(), "bin", "cargo-tauri"]
      |> Path.join()
      |> System.cmd(args, opts)
  end

  defp get_app_name() do
    Application.get_env(:ex_tauri, :app_name) || raise "Provide the :app_name in your app config for :ex_tauri"
  end

  def build_package_name() do
    get_app_name()
    |> String.replace("\s", "")
    |> Macro.underscore()
  end

  # The release name needs to be unique, otherwise any app built by burrito will always
  # be installed in the same path on the target
  defp build_release_name() do
    "desktop_#{build_package_name()}"
  end

  defp wrap() do

    # File.rm_rf!(Path.join([Path.expand("~"), "Library", "Application Support", ".burrito"]))

    release_name = build_release_name()

    releases = get_in(Mix.Project.config(), [:releases, release_name |> String.to_atom()]) ||
      raise "expected a burrito release configured for the app #{release_name} in your mix.exs"

    dbg(releases)

    # Mix.Task.run("release", [release_name])
    Mix.Task.run("release")

    triplet =
      System.cmd("rustc", ["-Vv"])
      |> elem(0)
      |> then(&Regex.run(~r/host: (.*)/, &1))
      |> Enum.at(1)

dbg(triplet)

    # File.cp!(
    #   "burrito_out/desktop_todo_trek_#{triplet}",
    #   "burrito_out/desktop_todo_trek-#{triplet}"
    # )

    File.cp!(
      "burrito_out/desktop_todo_trek_#{triplet}",
      "burrito_out/desktop_todo_trek-#{triplet}"
    )

    :ok
  end

  defp cargo_toml(app_name) do
    package_name = build_package_name()
    # release_name = build_release_name()
    version = Application.get_env(:ex_tauri, :app_version, "0.1.0")
    description = Application.get_env(:ex_tauri, :app_description, "A Phoenix Tauri App")
    authors = Application.get_env(:ex_tauri, :app_authors, [app_name]) |> Enum.join("\",\"")
    app_license = Application.get_env(:ex_tauri, :app_license, "Proprietary")
    app_homepage = Application.get_env(:ex_tauri, :app_homepage, "example.com")
    app_repository = Application.get_env(:ex_tauri, :app_repository, "example.com")
    rust_edition = Application.get_env(:ex_tauri, :rust_edition, "2021")

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

    [features]
    # by default Tauri runs in production mode
    # when `tauri dev` runs it is executed with `cargo run --no-default-features` if `devPath` is an URL
    default = [ "custom-protocol" ]

    # this feature is used for production builds where `devPath` points to the filesystem
    # DO NOT remove this
    custom-protocol = [ "tauri/custom-protocol" ]
    """
  end

  defp main_src(host, port) do
    release_name = build_release_name()

    """
    // Prevents additional console window on Windows in release, DO NOT REMOVE!!
    #![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
    use tauri::api::process::{Command, CommandEvent};

    fn main() {
        tauri::Builder::default()
            .setup(|_app| {
                start_server();
                check_server_started();
                Ok(())
            })
            .run(tauri::generate_context!())
            .expect("error while running tauri application");
    }
    fn start_server() {
        tauri::async_runtime::spawn(async move {
            let (mut rx, mut _child) = Command::new_sidecar("#{release_name}")
                .expect("failed to setup `#{release_name}` sidecar")
                .spawn()
                .expect("Failed to spawn sidecar for #{release_name}");

            while let Some(event) = rx.recv().await {
                if let CommandEvent::Stdout(line) = event {
                    println!("{}", line);
                }
            }
        });
    }

    fn check_server_started() {
        let sleep_interval = std::time::Duration::from_millis(200);
        let host = "#{host}".to_string();
        let port = "#{port}".to_string();
        let addr = format!("{}:{}", host, port);
        println!(
            "Waiting for your phoenix dev server to start on {}",
            addr
        );
        loop {
            if std::net::TcpStream::connect(addr.clone()).is_ok() {
              println!(".");
              break;
            }
            std::thread::sleep(sleep_interval);
        }
    }

    """
  end
end
