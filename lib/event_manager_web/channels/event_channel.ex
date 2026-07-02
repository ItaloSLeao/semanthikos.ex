defmodule EventManagerWeb.EventChannel do
  @moduledoc """
  Phoenix Channel for real-time event updates.
  Handles registration updates, capacity warnings, and event reminders.
  """
  use EventManagerWeb, :channel

  @impl true
  def join("event:" <> event_id, _params, socket) do
    event = EventManager.Core.get_event!(event_id)

    {:ok,
     %{
       event_id: event_id,
       remaining_seats: EventManager.Schemas.Event.remaining_seats(event)
     }, socket}
  end

  @impl true
  def handle_in("request_update", _payload, socket) do
    "event:" <> event_id = socket.topic
    event = EventManager.Core.get_event!(event_id)

    push(socket, "status_update", %{
      remaining_seats: EventManager.Schemas.Event.remaining_seats(event)
    })

    {:reply, :ok, socket}
  end
end
