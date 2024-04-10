import Config

config :example_desktop, ExampleDesktopWeb.Endpoint,
  secret_key_base: :crypto.strong_rand_bytes(64) |> Base.encode64(),
  server: true

# For SQLite3:
# Needs to match the dir created in the prod.Dockerfile, therefore it's best to
# not customize it with an env var.
database_dir = ".database/sqlite3"

# For SQLite3:
database_filename =
  case config_env() do
    :test ->
      # The MIX_TEST_PARTITION environment variable can be used
      # to provide built-in test partitioning in CI environment.
      # Run `mix help test` for more information.
      "example_desktop_#{System.get_env("MIX_TEST_PARTITION", "")}.db"

    _ ->
      "example_desktop.db"
  end

database_path =
  Path.expand("#{database_dir}/#{config_env()}/#{database_filename}", Path.dirname(__DIR__))

# For SQLite3:
config :example_desktop, ExampleDesktop.Repo,
  database: database_path,
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10")),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

if config_env() == :prod do
  # For SQLite3:
  config :example_desktop, ExampleDesktop.Repo,
    stacktrace: false,
    show_sensitive_data_on_connection_error: false
end
