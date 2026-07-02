defmodule EventManagerWeb.NotificationChannel do
  @moduledoc """
  Phoenix Channel for event notifications.
  Broadcasts capacity warnings and reminders.
  """
  use EventManagerWeb, :channel

  @impl true
  def join("event_notifications:" <> event_id, _params, socket) do
    {:ok, %{event_id: event_id}, socket}
  end

  @impl true
  def handle_in("ping", _payload, socket) do
    {:reply, {:ok, %{status: "pong"}}, socket}
  end
end
