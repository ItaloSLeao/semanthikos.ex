defmodule EventManagerWeb.Api.EventController do
  use EventManagerWeb, :controller


  def index(conn, params) do
    events = EventManager.Core.list_events(params)
    render(conn, :index, events: events)
  end

  def show(conn, %{"id" => id}) do
    event = EventManager.Core.get_event!(id)
    render(conn, :show, event: event)
  end

  def stats(conn, %{"id" => id}) do
    stats = EventManager.Core.get_event_stats(id)
    json(conn, stats)
  end
end