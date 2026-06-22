defmodule EventManagerWeb.AdminController do
  @moduledoc """
  Controller for admin operations (events, users, reports, certificates).
  """
  use EventManagerWeb, :controller

  
  alias EventManager.Schemas.Event

  ## Event Management
  def events(conn, _params), do: render(conn, "events.html", events: EventManager.Core.list_events())

  def new_event(conn, _params) do
    render(conn, "event_new.html", changeset: Event.changeset(%Event{}, %{}), speakers: EventManager.Core.list_speakers())
  end

  def create_event(conn, %{"event" => event_params}) do
    {event_params, upload} = pop_event_banner(conn, event_params)

    with {:ok, event_params} <- maybe_put_event_banner(upload, event_params) do

      case EventManager.Core.create_event(event_params) do
        {:ok, _event} ->
          conn
          |> put_flash(:info, "Evento criado com sucesso!")
          |> redirect(to: ~p"/events") # Redireciona direto para o catálogo para ver o resultado
        {:error, changeset} ->
          render(conn, "event_new.html", changeset: changeset, speakers: EventManager.Core.list_speakers())
      end
    else
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> render("event_new.html", changeset: Event.changeset(%Event{}, event_params), speakers: EventManager.Core.list_speakers())
    end
  end

  def edit_event(conn, %{"id" => id}) do
    event = EventManager.Core.get_event!(id)
    render(conn, "event_edit.html", event: event, changeset: Event.changeset(event, %{}), speakers: EventManager.Core.list_speakers())
  end

  def update_event(conn, %{"id" => id, "event" => event_params}) do
    event = EventManager.Core.get_event!(id)
    {event_params, upload} = pop_event_banner(conn, event_params)

    with {:ok, event_params} <- maybe_put_event_banner(upload, event_params) do
      case EventManager.Core.update_event(event, event_params) do
        {:ok, event} -> conn |> put_flash(:info, "Evento atualizado com sucesso.") |> redirect(to: ~p"/admin/events/#{event.id}/edit")
        {:error, changeset} -> render(conn, "event_edit.html", event: event, changeset: changeset, speakers: EventManager.Core.list_speakers())
      end
    else
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> render("event_edit.html", event: event, changeset: Event.changeset(event, event_params), speakers: EventManager.Core.list_speakers())
    end
  end

  def delete_event(conn, %{"id" => id}) do
    case EventManager.Core.delete_event(EventManager.Core.get_event!(id)) do
      {:ok, _} -> conn |> put_flash(:info, "Evento excluído com sucesso.") |> redirect(to: ~p"/admin/events")
      {:error, :has_registrations} -> conn |> put_flash(:error, "Não é possível excluir evento com inscrições.") |> redirect(to: ~p"/admin/events")
    end
  end

  def publish_event(conn, %{"id" => id}) do
    case EventManager.Core.publish_event(EventManager.Core.get_event!(id)) do
      {:ok, _} -> conn |> put_flash(:info, "Evento publicado com sucesso.") |> redirect(to: ~p"/admin/events/#{id}/edit")
      {:error, _} -> conn |> put_flash(:error, "Erro ao publicar evento.") |> redirect(to: ~p"/admin/events/#{id}/edit")
    end
  end

  def cancel_event(conn, %{"id" => id}) do
    case EventManager.Core.cancel_event(EventManager.Core.get_event!(id)) do
      {:ok, _} -> conn |> put_flash(:info, "Evento cancelado.") |> redirect(to: ~p"/admin/events/#{id}/edit")
      {:error, _} -> conn |> put_flash(:error, "Erro ao cancelar evento.") |> redirect(to: ~p"/admin/events/#{id}/edit")
    end
  end

  ## User Management
  def users(conn, _params), do: render(conn, "users.html", users: EventManager.Core.list_users())
  def new_user(conn, _params), do: render(conn, "user_new.html")

  def create_user(conn, %{"user" => user_params}) do
    case EventManager.Core.register_user(user_params) do
      {:ok, _user} -> conn |> put_flash(:info, "Usuário criado com sucesso.") |> redirect(to: ~p"/admin/users")
      {:error, _} -> conn |> put_flash(:error, "Erro ao criar usuário.") |> redirect(to: ~p"/admin/users/new")
    end
  end

  def edit_user(conn, %{"id" => id}), do: render(conn, "user_edit.html", user: EventManager.Core.get_user!(id))

  def update_user(conn, %{"id" => id, "user" => user_params}) do
    user = EventManager.Core.get_user!(id)
    case EventManager.Core.update_user_profile(user, user_params) do
      {:ok, _} -> conn |> put_flash(:info, "Usuário atualizado com sucesso.") |> redirect(to: ~p"/admin/users")
      {:error, _} -> render(conn, "user_edit.html", user: user)
    end
  end

  def delete_user(conn, %{"id" => id}) do
    user = EventManager.Core.get_user!(id)
    if conn.assigns.current_user.id == user.id do
      conn |> put_flash(:error, "Você não pode excluir sua própria conta.") |> redirect(to: ~p"/admin/users")
    else
      EventManager.Core.delete_user_session_token(user)
      conn |> put_flash(:info, "Usuário excluído com sucesso.") |> redirect(to: ~p"/admin/users")
    end
  end

  ## Reports
  def reports(conn, _params) do
    render(conn, "reports.html", stats: EventManager.Services.get_system_stats(), monthly_stats: EventManager.Services.get_monthly_stats())
  end

  def occupancy_report(conn, _params), do: render(conn, "occupancy_report.html", data: EventManager.Services.get_occupancy_report(limit: 20))
  def participation_report(conn, _params), do: render(conn, "participation_report.html", by_course: EventManager.Services.get_participation_by_course(), by_department: EventManager.Services.get_participation_by_department())

  def export_csv(conn, %{"type" => "events"}) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=eventos.csv")
    |> send_resp(200, EventManager.Services.export_events_csv())
  end

  def export_csv(conn, %{"event_id" => event_id}) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=inscricoes-evento-#{event_id}.csv")
    |> send_resp(200, EventManager.Services.export_registrations_csv(event_id))
  end

  ## Certificates
  def certificates(conn, _params), do: conn |> redirect(to: ~p"/admin/events")

  def generate_certificates(conn, %{"event_id" => event_id}) do
    count = EventManager.Services.generate_event_certificates(event_id)
    conn |> put_flash(:info, "#{count} certificados gerados com sucesso.") |> redirect(to: ~p"/admin/events")
  end

  defp pop_event_banner(%{params: %{"event_banner" => %Plug.Upload{} = upload}}, event_params) do
    {Map.delete(event_params, "banner"), upload}
  end

  defp pop_event_banner(_conn, %{"banner" => %Plug.Upload{} = upload} = event_params) do
    {Map.delete(event_params, "banner"), upload}
  end

  defp pop_event_banner(_conn, event_params), do: {Map.delete(event_params, "banner"), nil}

  defp maybe_put_event_banner(nil, event_params), do: {:ok, event_params}

  defp maybe_put_event_banner(%Plug.Upload{} = upload, event_params) do
    allowed_extensions = ~w(.jpg .jpeg .png .webp)
    max_size = 5 * 1024 * 1024
    extension = upload.filename |> Path.extname() |> String.downcase()
    size = File.stat!(upload.path).size

    cond do
      extension not in allowed_extensions ->
        {:error, "Banner inválido. Envie uma imagem JPG, PNG ou WEBP."}

      size > max_size ->
        {:error, "Banner muito grande. O limite é 5 MB."}

      true ->
        upload_path = Path.join(:code.priv_dir(:event_manager), "static/uploads/events")
        File.mkdir_p!(upload_path)

        filename = "#{System.unique_integer([:positive])}-event-banner#{extension}"
        destination = Path.join(upload_path, filename)
        File.cp!(upload.path, destination)

        {:ok, Map.put(event_params, "image_url", "/uploads/events/#{filename}")}
    end
  end

end
