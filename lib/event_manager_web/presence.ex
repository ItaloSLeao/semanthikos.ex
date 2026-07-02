defmodule EventManagerWeb.Presence do
  @moduledoc """
  Presence tracking for LiveView and Channels.
  Tracks which users are online in event sessions.
  """
  use Phoenix.Presence,
    otp_app: :event_manager,
    pubsub_server: EventManager.PubSub

  @impl true
  def fetch(_topic, presences) do
    users =
      presences
      |> Map.keys()
      |> EventManager.Core.list_users_by_ids()

    presences
    |> Enum.map(fn {key, %{metas: metas}} ->
      user = Enum.find(users, &(&1.id == String.to_integer(key)))
      {key, %{metas: metas, user: user}}
    end)
    |> Enum.into(%{})
  end
end
