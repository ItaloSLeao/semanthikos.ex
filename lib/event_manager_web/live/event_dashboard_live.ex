defmodule EventManagerWeb.EventDashboardLive do
  @moduledoc "LiveView for real-time event dashboard."
  use EventManagerWeb, :live_view

  @impl true
  def mount(%{"id" => event_id}, session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(EventManager.PubSub, "event:#{event_id}")

    current_user = EventManager.Core.get_user_by_session_token(session["user_token"])
    event = EventManager.Core.get_event_with_registrations!(event_id)

    {:ok,
     assign(socket,
       event: event,
       stats: EventManager.Core.get_event_stats(event_id),
       current_user: current_user
     )}
  end

  @impl true
  def handle_event("refresh", _params, socket),
    do:
      {:noreply,
       assign(socket, stats: EventManager.Core.get_event_stats(socket.assigns.event.id))}

  @impl true
  def handle_info(%{event: "registration_updated"}, socket),
    do:
      {:noreply,
       assign(socket, stats: EventManager.Core.get_event_stats(socket.assigns.event.id))}
end
