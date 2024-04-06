defmodule ExTauri.AppConfig do

	def get(app, key, default \\ nil) do
	   Application.get_env(app, key, default)
	end

	def get!(app, key) do
	  Application.get_env(app, key) || Mix.raise("Your config is missing the key :#{key} for #{app}.")
	end

end
