defmodule EventManagerWeb.Api.EventJSON do
  alias EventManager.Schemas.Event

  def index(%{events: events}) do
    %{data: for(event <- events, do: data(event))}
  end

  def show(%{event: event}) do
    %{data: data(event)}
  end

  def data(%Event{} = event) do
    %{
      id: event.id,
      title: event.title,
      description: event.description,
      date: event.date,
      location: event.location,
      max_seats: event.max_seats,
      remaining_seats: Event.remaining_seats(event),
      status: event.status,
      is_online: event.is_online,
      online_url: event.online_url
    }
  end
end