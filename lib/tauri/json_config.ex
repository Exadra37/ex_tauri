defmodule ExTauri.Tauri.JsonConfig do

	require Logger

	def upsert(burrito_bin_path) do
	  burrito_bin_path = "../" <> burrito_bin_path
	  path = [File.cwd!(), "src-tauri", "tauri.conf.json"] |> Path.join()

	  Logger.warning("Upserting Tauri json config at: " <> path)

	  app_version = ExTauri.get_project_config(:version, "0.1.0")
	  app_name = ExTauri.get_config!(:ex_tauri, :app_name)
	  window_title = Application.get_env(:ex_tauri, :window_title, app_name)
	  fullscreen = Application.get_env(:ex_tauri, :fullscreen, false)
	  height = Application.get_env(:ex_tauri, :height, 600)
	  width = Application.get_env(:ex_tauri, :width, 800)
	  resize = Application.get_env(:ex_tauri, :resize, true)

	  # Add side car and required configuration to tauri.conf.json
	  path
	  |> File.read!()
	  |> Jason.decode!()
	  |> then(fn content ->
	    content
	    |> put_in(["package"], %{
	    		productName: app_name,
	    		version: app_version
	    	})
	    |> put_in(["tauri", "bundle", "externalBin"], [burrito_bin_path])
	    |> put_in(
	      ["tauri", "bundle", "identifier"],
	      "you.app.#{app_name |> String.replace("\s", "") |> Macro.underscore() |> String.replace("_", "-")}"
	    )
	    |> put_in(["tauri", "allowlist"], %{
	      shell: %{
	        sidecar: true,
	        scope: [%{name: burrito_bin_path, sidecar: true, args: ["start"]}]
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

end
