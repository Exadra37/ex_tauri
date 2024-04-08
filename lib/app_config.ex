defmodule ExTauri.AppConfig do

	def get(app, key, default \\ nil) do
	   Application.get_env(app, key, default)
	end

	def get!(app, key) do
	  Application.get_env(app, key) || Mix.raise("Your config is missing the key :#{key} for :#{app}.")
	end

	def get_project(key, default \\ nil) do
		Mix.Project.config()
		|> Keyword.get(key, default)
	end

	def get_project!(key) do
		key
		|> get_project()
		|> case do
			nil ->
				Mix.raise("project/1 is missing the :#{key} on your mix.exs")

			value ->
				value
		end
	end

end
