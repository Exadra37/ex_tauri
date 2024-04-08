defmodule ExTauri.Tauri.BundleRelease do

  require Logger

  def build([]) do
    Logger.error("Please provide the command for cargo_tauri, e.g build")
  end

  def build(args) when is_list(args) do
    :releases
    |> ExTauri.get_project_config()
    |> build_releases(args)
  end

  defp build_releases([], _args) do
    Logger.error("project/1 is missing :releases configured on your mix.exs")
  end

  defp build_releases(releases, args) do
    dbg(releases)

    with [] <- validate_releases_config(releases) do
      releases
      |> Enum.map(fn {release_name, release_config} ->build_release(release_name, release_config, args) end)

    else
      errors ->
        errors
        |> Enum.each(fn error -> Logger.error("#{error}") end)
    end
  end

  defp validate_releases_config(releases) do
    releases
    |> Enum.reduce([], fn release, acc -> validate_release_config(release, acc) end)
  end

  defp validate_release_config({release_name, release_config}, errors) do
    burrito_config = Keyword.get(release_config, :burrito)

    if is_nil(burrito_config) do
      ["expected a burrito release configured for the app #{release_name} in your mix.exs" | errors]
    else
      errors
    end
  end

  defp build_release(release_name, release_config, args) when is_atom(release_name) do
    release_name
    |> Atom.to_string()
    |> build_release(release_config, args)
  end

  defp build_release(release_name, release_config, args) do
    release_name
    |> burrito_wrap_release()
    |> build_tauri_release(release_config, args)
  end

  defp burrito_wrap_release(release_name) do
    Mix.Task.run("release", [release_name])
    release_name
  end

  def build_tauri_release(release_name, release_config, args) do
    System.put_env("TAURI_SKIP_DEVSERVER_CHECK", "true")

    Keyword.get(release_config, :burrito)
    |> Keyword.get(:targets)
    |> Enum.each(fn
      {platform, target}->
        build_tauri_for_target(target, release_name, platform, args)
      end)
  end

  defp build_tauri_for_target(target, release_name, platform, args) do
    os = target |> Keyword.get(:os) |> Atom.to_string()
    cpu = target |> Keyword.get(:cpu) |> Atom.to_string()
    compiler_type = target |> Keyword.get(:x_compiler_type)
    target_triple = build_target_triple(platform, cpu, os, compiler_type)

    rename_burrito_binary(platform, release_name, target_triple)

    ExTauri.override_cargo_toml_config()
    ExTauri.override_main_src_code(release_name)

    burrito_bin_path = build_burrito_output_partial_path(release_name)
    ExTauri.upsert_tauri_json_config(burrito_bin_path)

    args =
      args
      |> add_platform_args(platform, compiler_type)
      |> add_cargo_tauri_args(target_triple)

    opts = [
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true,
    ]

    Logger.info("Running command `bin/cargo_tauri` with args `" <> inspect(args) <> "` and opts `" <> inspect(opts) <> "`")

    {_, exit_code} =
       [ExTauri.installation_path(), "bin", "cargo-tauri"]
       |> Path.join()
       |> System.cmd(args, opts)

    exit_code
  end

  defp add_platform_args(args, :windows, :msvc) do
    args
    |> List.insert_at( -1, "--runner")
    |> List.insert_at( -1, "cargo-xwin")
  end

  defp add_platform_args(args, _platform, _compiler_type), do: args

  defp add_cargo_tauri_args(args, target_triple) do
    args
    |> List.insert_at( -1, "--target")
    |> List.insert_at( -1, target_triple)
  end

  defp build_target_triple(:linux, cpu, _os, :musl), do: cpu <> "-" <> "unknown-linux-musl"
  defp build_target_triple(:linux, cpu, _os, _), do: cpu <> "-" <> "unknown-linux-gnu"
  defp build_target_triple(:windows, cpu, _os, :msvc), do: cpu <> "-" <> "pc-windows-msvc"
  defp build_target_triple(:windows, cpu, _os, _), do: cpu <> "-" <> "pc-windows-gnu"
  defp build_target_triple(platform, cpu, os, _) when platform in [:macos, :macos_m1], do: cpu <> "-" <> "apple" <> "-" <> os

  # The build name needs to be unique, otherwise any app built by burrito will always
  # be installed in the same path on the target
  defp build_burrito_output_partial_path(release_name) do
    "burrito_out/#{release_name}"
  end

  defp rename_burrito_binary(:windows, release_name, target_triple) do
    rename_burrito_binary(:"windows.exe", release_name, target_triple <> ".exe")
  end

  defp rename_burrito_binary(platform, release_name, target_triple) do
    burrito_output = build_burrito_output_partial_path(release_name)
    platform =  Atom.to_string(platform)
    from = burrito_output <> "_" <> platform
    to = burrito_output <> "-" <>  target_triple

    Logger.info("Renaming burrito build from #{from} to #{to}")

    File.rename(from, to)
  end
end
