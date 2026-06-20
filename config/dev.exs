import Config

config :event_manager, EventManager.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "event_manager_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :event_manager, EventManagerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "MsewRPgkU7gCViZMekeCigaSDplRjk7irnmYrG4HIQWQ4vcqirbtap90QqTl1jHRmN7J5916hQpS7k5R9b4G6",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w()]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/event_manager_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :event_manager, dev_routes: true

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :event_manager, EventManager.Mailer, adapter: Swoosh.Adapters.Local

config :event_manager, EventManagerWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{lib/event_manager_web/.*(ex|heex)$}
    ]
  ]