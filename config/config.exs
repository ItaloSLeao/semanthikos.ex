# General application configuration
import Config

config :event_manager,
  ecto_repos: [EventManager.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :event_manager, EventManagerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: EventManagerWeb.ErrorHTML, json: EventManagerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: EventManager.PubSub,
  live_view: [signing_salt: "YourSecretKeyHere123"]

# Configures the mailer
config :event_manager, EventManager.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure Phoenix connections
config :phoenix, :json_library, Jason

# Configures bcrypt for password hashing
config :bcrypt_elixir, log_rounds: 12

# PDF Generator configuration
config :pdf_generator, safe_relative_path: System.tmp_dir!()
config :pdf_generator, raise_on_missing_wkhtmltopdf_binary: false

# Import environment specific config
import_config "#{config_env()}.exs"

config :esbuild,
  version: "0.25.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "4.1.12",
  default: [
    args: ~w(
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
