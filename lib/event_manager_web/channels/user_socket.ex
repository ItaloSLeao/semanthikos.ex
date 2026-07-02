defmodule EventManagerWeb.UserSocket do
  @moduledoc """
  WebSocket handler for Phoenix Channels.
  Handles authentication and channel routing.
  """
  use Phoenix.Socket

  channel "event:*", EventManagerWeb.EventChannel
  channel "event_chat:*", EventManagerWeb.ChatChannel
  channel "event_notifications:*", EventManagerWeb.NotificationChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case EventManager.Core.get_user_by_session_token(token) do
      nil -> :error
      user -> {:ok, assign(socket, :current_user, user)}
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(_socket), do: nil
end
