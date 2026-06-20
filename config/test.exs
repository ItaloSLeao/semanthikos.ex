import Config

config :bcrypt_elixir, :log_rounds, 4

config :event_manager, EventManager.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "event_manager_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :event_manager, EventManagerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "uRkC9iV4L+lK1O+/M+a9/M/Q1xW1A9v6Wq4c6tZ3A8N1aD4=",
  server: false

config :swoosh, :api_client, false
config :event_manager, EventManager.Mailer, adapter: Swoosh.Adapters.Test

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
config :pdf_generator, raise_on_missing_wkhtmltopdf_binary: false
