defmodule ExTauri.Tauri.Install do

  @latest_version "1.5.11"
  def latest_version, do: @latest_version

	def install(extra_args \\ []) do
	  app_name = ExTauri.get_config!(:ex_tauri, :app_name)
	  window_title = ExTauri.get_config(:ex_tauri, :window_title, app_name)
	  scheme = ExTauri.get_config(:ex_tauri, :scheme, "http")
	  host = ExTauri.get_config!(:ex_tauri, :host)
	  port = ExTauri.get_config!(:ex_tauri, :port)
	  cli_version = ExTauri.get_config(:ex_tauri, :cli_version, latest_version())
	  installation_path = installation_path()
	  File.mkdir_p!(installation_path)

	  opts = [
	    cd: installation_path,
	    into: IO.stream(:stdio, :line),
	    stderr_to_stdout: true
	  ]

	  System.cmd("cargo", ["install", "tauri-cli@#{cli_version}", "--root", "."], opts)

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

	  # TODO remove this when possible, for some reason it's failing at the moment
	  File.cp!(
	    Path.join([File.cwd!(), "src-tauri", "build.rs"]),
	    Path.join([File.cwd!(), "src-tauri", "src", "build.rs"])
	  )
	end

	@doc """
	Returns the path to the executable.

	The executable may not be available if it was not yet installed.
	"""
	def installation_path do
	  ExTauri.get_config(:ex_tauri, :path) ||
	    if Code.ensure_loaded?(Mix.Project) do
	      Path.join(Path.dirname(Mix.Project.build_path()), "_tauri")
	    else
	      Path.expand("_build/_tauri")
	    end
	end
end
