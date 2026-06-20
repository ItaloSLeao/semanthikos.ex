defmodule EventManagerWeb.EventController do
  @moduledoc """
  Controller for event operations (viewing, registration, user registrations, speaker operations).
  Consolidates EventController, RegistrationController, and SpeakerController.
  """
  use EventManagerWeb, :controller

  alias EventManager.Schemas.Event

  # --- Public Event Viewing ---
  def index(conn, _params) do
    events = EventManager.Core.list_events(
      status: :published,
      upcoming_only: true,
      order_by: {:date, :asc}
    )
    render(conn, :index, events: events)
  end

  def show(conn, %{"id" => id}) do
    event = EventManager.Core.get_event_with_registrations!(id)
    current_user = conn.assigns[:current_user]
    registration = current_user && EventManager.Core.get_registration(id, current_user.id)

    render(conn, :show,
      event: event,
      registration: registration,
      remaining_seats: Event.remaining_seats(event)
    )
  end

  # --- Registration ---
  def register(conn, %{"id" => event_id}) do
    user = conn.assigns.current_user
    event_id_int = if is_binary(event_id), do: String.to_integer(event_id), else: event_id

    case EventManager.Core.register_for_event(event_id_int, user.id) do
      {:ok, _registration} ->
        conn |> put_flash(:info, "Inscrição realizada com sucesso!") |> redirect(to: ~p"/events/#{event_id}")
      {:error, :no_seats_available} ->
        conn |> put_flash(:error, "Evento está cheio. Não há mais vagas disponíveis.") |> redirect(to: ~p"/events/#{event_id}")
      {:error, _} ->
        conn |> put_flash(:error, "Erro ao realizar inscrição. Tente novamente.") |> redirect(to: ~p"/events/#{event_id}")
    end
  end

  def cancel_registration(conn, %{"id" => event_id}) do
    user = conn.assigns.current_user
    event_id_int = if is_binary(event_id), do: String.to_integer(event_id), else: event_id

    case EventManager.Core.cancel_registration(event_id_int, user.id) do
      {:ok, :cancelled} ->
        conn |> put_flash(:info, "Inscrição cancelada com sucesso.") |> redirect(to: ~p"/events/#{event_id}")
      {:error, :not_found} ->
        conn |> put_flash(:error, "Inscrição não encontrada.") |> redirect(to: ~p"/events/#{event_id}")
    end
  end

  # --- User Registrations (requires auth) ---
  def my_registrations(conn, _params) do
    user = conn.assigns.current_user
    registrations = EventManager.Core.list_user_registrations(user.id)
    render(conn, "registrations_index.html", registrations: registrations)
  end

  # --- Speaker Operations ---
  def speaker_events(conn, _params) do
    user = conn.assigns.current_user
    events = EventManager.Core.list_events(speaker_id: user.id)
    render(conn, "speaker_events.html", events: events)
  end

  def speaker_attendees(conn, %{"id" => event_id}) do
    event = EventManager.Core.get_event_with_registrations!(event_id)
    user = conn.assigns.current_user

    if user.role == :admin or event.speaker_id == user.id do
      render(conn, "speaker_attendees.html", event: event)
    else
      conn |> put_flash(:error, "Sem permissão.") |> redirect(to: ~p"/")
    end
  end

  def mark_attendance(conn, %{"event_id" => event_id, "registration_id" => registration_id, "attended" => attended}) do
    case EventManager.Core.mark_attendance(registration_id, attended == "true") do
      {:ok, _} ->
        conn |> put_flash(:info, "Presença atualizada com sucesso.") |> redirect(to: ~p"/speaker/events/#{event_id}/attendees")
      {:error, _} ->
        conn |> put_flash(:error, "Erro ao atualizar presença.") |> redirect(to: ~p"/speaker/events/#{event_id}/attendees")
    end
  end

  def generate_certificates(conn, %{"event_id" => event_id}) do
    event = EventManager.Core.get_event!(event_id)
    user = conn.assigns.current_user

    if user.role == :admin or event.speaker_id == user.id do
      count = EventManager.Services.generate_event_certificates(event_id)
      conn 
      |> put_flash(:info, "#{count} certificados gerados com sucesso.") 
      |> redirect(to: ~p"/speaker/events/#{event_id}/attendees")
    else
      conn |> put_flash(:error, "Sem permissão.") |> redirect(to: ~p"/")
    end
  end
end