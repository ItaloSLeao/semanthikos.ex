defmodule EventManager.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :event_manager,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {EventManager.Application, []},
      extra_applications: [:logger, :runtime_tools, :ssl]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix Framework
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_dashboard, "~> 0.8.2"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},

      # LiveView for real-time UI
      {:phoenix_live_view, "~> 0.20.1"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},

      # Internationalization
      {:gettext, "~> 0.20"},

      # Database
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},

      # Authentication (implemented manually)
      {:bcrypt_elixir, "~> 3.0"},

      # Real-time communication
      {:phoenix_pubsub, "~> 2.1"},

      # Web server
      {:plug_cowboy, "~> 2.6"},

      # Telemetry for monitoring
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},

      # JSON handling
      {:jason, "~> 1.4"},

      # Build tools
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},

      # Swoosh for emails
      {:swoosh, "~> 1.14"},
      {:pdf_generator, ">= 0.6.0"},
      {:hackney, "~> 1.9"},
      {:finch, "~> 0.13"},

      # CSV Export
      {:csv, "~> 3.0"},

      # Testing
      {:floki, ">= 0.30.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --no-deps", "esbuild.install --no-deps"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify"]
    ]
  end
end
