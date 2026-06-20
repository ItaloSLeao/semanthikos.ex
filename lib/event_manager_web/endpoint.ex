defmodule EventManagerWeb.Endpoint do
  
  
  @moduledoc """
  Phoenix endpoint configuration.
  Handles HTTP requests, WebSocket connections, and static file serving.
  """
  use Phoenix.Endpoint, otp_app: :event_manager

  # Serve static files
  plug Plug.Static,
    at: "/",
    from: :event_manager,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt uploads)

  # Code reloading for development
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :event_manager
  end

  @session_options [
    store: :cookie,
    key: "_event_manager_key",
    signing_salt: "SigningSalt123",
    same_site: "Lax"
  ]

  # WebSocket for real-time features (LiveView and Channels)
  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]
  socket "/socket", EventManagerWeb.UserSocket, websocket: true, longpoll: false

  # Session handling
  plug Plug.Session, @session_options

  # Request pipeline
  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # Security headers
  plug Plug.SSL, rewrite_on: [:x_forwarded_proto]

  # Router
  plug EventManagerWeb.Router
end