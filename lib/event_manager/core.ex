defmodule EventManager.Core do
  @moduledoc """
  Gerente Principal do Event Manager.

  Este módulo é o coração da camada de negócios (backend), responsável pelo contexto consolidado de Accounts (Autenticação, Usuários) e Events (CRUD de eventos, Inscrições).
  Ele segue o padrão de "Gerentes de Departamento" para consolidar lógicas relacionadas e reduzir boilerplate.

  Principais responsabilidades:
  - Criação e validação de usuários.
  - Publicação, edição e cancelamento de eventos.
  - Lida com a regra de negócio central, garantindo isolamento da camada Web.
  """
  import Ecto.Query
  alias EventManager.Repo
  alias EventManager.Schemas.{User, UserToken, Event, Registration}
  alias EventManager.UserNotifier

  ## --- ACCOUNTS ---

  def get_user_by_email(email) when is_binary(email), do: Repo.get_by(User, email: email)

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  defp parse_id(id) when is_binary(id), do: String.to_integer(id)
  defp parse_id(id), do: id

  def get_user!(id), do: Repo.get!(User, id)

  def list_users_by_ids(ids) do
    ids = Enum.map(ids, &parse_id/1)
    from(u in User, where: u.id in ^ids) |> Repo.all()
  end

  def list_users(opts \\ []) do
    from(u in User, order_by: [asc: u.name])
    |> maybe_filter_role(opts[:role])
    |> Repo.all()
  end

  def list_admins, do: Repo.all(from u in User, where: u.role == :admin)
  def list_speakers, do: Repo.all(from u in User, where: u.role == :speaker)

  defp maybe_filter_role(q, nil), do: q
  defp maybe_filter_role(q, role), do: where(q, [u], u.role == ^role)

  def register_user(attrs), do: %User{} |> User.registration_changeset(attrs) |> Repo.insert()
  def register_admin(attrs), do: register_user(Map.put(attrs, :role, :admin))
  def register_speaker(attrs), do: register_user(Map.put(attrs, :role, :speaker))

  def change_user_email(user, attrs \\ %{}), do: User.email_changeset(user, attrs)
  def update_user_profile(user, attrs), do: user |> User.profile_changeset(attrs) |> Repo.update()

  def update_user_password(user, attrs),
    do: user |> User.password_changeset(attrs) |> Repo.update()

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    case UserToken.verify_session_token_query(token) |> Repo.one() do
      nil -> nil
      user -> user
    end
  end

  def delete_user_session_token(token),
    do: UserToken.by_token_and_context_query(token, "session") |> Repo.delete_all()

  def deliver_user_confirmation_instructions(user, confirmation_url_fun) do
    if user.confirmed_at,
      do: {:error, :already_confirmed},
      else: do_confirm(user, confirmation_url_fun)
  end

  defp do_confirm(user, url_fun) do
    {token, user_token} = UserToken.build_email_token(user, "confirm")
    Repo.insert!(user_token)
    UserNotifier.deliver_confirmation_instructions(user, url_fun.(token))
  end

  def confirm_user(token) do
    case UserToken.verify_email_token_query(token, "confirm") |> Repo.one() do
      nil -> {:error, :invalid_token}
      user -> user |> User.confirm_changeset() |> Repo.update() |> confirm_result(user)
    end
  end

  defp confirm_result({:ok, user}, user), do: UserToken.delete_all_for_user(user, "confirm")
  defp confirm_result(error, _), do: error

  def deliver_user_reset_password_instructions(user, url_fun) do
    {token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, url_fun.(token))
  end

  def get_user_by_reset_password_token(token),
    do: UserToken.verify_email_token_query(token, "reset_password") |> Repo.one()

  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  ## --- EVENTS ---

  def list_events(opts \\ []) do
    from(e in Event, preload: [:speaker, :registrations])
    |> filter_status(opts[:status])
    |> filter_speaker(opts[:speaker_id])
    |> filter_upcoming(opts[:upcoming_only])
    |> order_events(opts[:order_by] || {:date, :asc})
    |> paginate(opts[:page], opts[:per_page])
    |> Repo.all()
  end

  def get_event!(id), do: Event |> Repo.get!(id) |> Repo.preload([:speaker, :registrations])

  def get_event_with_registrations!(id),
    do: Event |> Repo.get!(id) |> Repo.preload([:speaker, registrations: [:user]])

  def create_event(attrs), do: %Event{} |> Event.changeset(attrs) |> Repo.insert()
  def update_event(%Event{} = event, attrs), do: event |> Event.changeset(attrs) |> Repo.update()
  def publish_event(%Event{} = event), do: event |> Event.publish_changeset() |> Repo.update()

  def cancel_event(%Event{} = event) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:event, Event.cancel_changeset(event))
    |> Ecto.Multi.run(:notifications, fn _repo, %{event: cancelled_event} ->
      # Notifica inscritos em tempo real via WebSocket antes de processar lógica pesada
      EventManagerWeb.Endpoint.broadcast(
        "event_notifications:#{cancelled_event.id}",
        "event_cancelled",
        %{title: cancelled_event.title, reason: "Evento cancelado pela administração"}
      )

      {:ok, :notified}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{event: event}} -> {:ok, event}
      {:error, _, error, _} -> {:error, error}
    end
  end

  def delete_event(%Event{} = event) do
    if EventManager.Schemas.Event.registration_count(event) > 0,
      do: {:error, :has_registrations},
      else: Repo.delete(event)
  end

  def register_for_event(event_id, user_id) do
    event_id = parse_id(event_id)
    user_id = parse_id(user_id)

    Repo.reserve_seat(event_id, user_id)
    |> case do
      {:ok, %{registration: reg}} ->
        EventManagerWeb.Endpoint.broadcast("event:#{event_id}", "registration_updated", %{
          event_id: event_id,
          remaining_seats: Event.remaining_seats(get_event!(event_id))
        })

        {:ok, reg}

      error ->
        error
    end
  end

  def cancel_registration(event_id, user_id) do
    event_id = parse_id(event_id)
    user_id = parse_id(user_id)

    registration = Repo.get_by(Registration, event_id: event_id, user_id: user_id)

    if registration do
      Ecto.Multi.new()
      |> Ecto.Multi.update(:cancel, Registration.cancel_changeset(registration))
      |> Ecto.Multi.run(:promote, fn repo, _ ->
        if registration.status == :confirmed do
          promote_waitlist(repo, event_id)
        else
          {:ok, nil}
        end
      end)
      |> Repo.transaction()
      |> case do
        {:ok, _} ->
          EventManagerWeb.Endpoint.broadcast("event:#{event_id}", "registration_updated", %{
            event_id: event_id,
            remaining_seats: Event.remaining_seats(get_event!(event_id))
          })

          {:ok, :cancelled}

        error ->
          error
      end
    else
      {:error, :not_found}
    end
  end

  defp promote_waitlist(repo, event_id) do
    next_in_line =
      from(r in Registration,
        where: r.event_id == ^event_id and r.status == :waitlisted,
        order_by: [asc: r.registered_at],
        limit: 1
      )
      |> repo.one()

    if next_in_line do
      next_in_line
      |> Ecto.Changeset.change(status: :confirmed)
      |> repo.update()
    else
      {:ok, nil}
    end
  end

  def get_registration(event_id, user_id) do
    event_id = parse_id(event_id)
    user_id = parse_id(user_id)
    Repo.get_by(Registration, event_id: event_id, user_id: user_id)
  end

  def mark_attendance(reg_id, attended) do
    reg_id = parse_id(reg_id)

    Repo.get!(Registration, reg_id)
    |> Registration.attendance_changeset(%{attended: attended})
    |> Repo.update()
  end

  def list_user_registrations(user_id) do
    user_id = parse_id(user_id)

    from(r in Registration,
      where: r.user_id == ^user_id and r.status != :cancelled,
      preload: [event: [:speaker]],
      order_by: [desc: r.registered_at]
    )
    |> Repo.all()
  end

  def list_event_registrations(event_id) do
    event_id = parse_id(event_id)

    from(r in Registration,
      where: r.event_id == ^event_id and r.status != :cancelled,
      preload: [:user],
      order_by: [asc: r.registered_at]
    )
    |> Repo.all()
  end

  def get_event_stats(event_id) do
    event_id = parse_id(event_id)
    event = get_event!(event_id)

    regs =
      from(r in Registration, where: r.event_id == ^event_id and r.status == :confirmed)
      |> Repo.aggregate(:count, :id)

    waitlisted =
      from(r in Registration, where: r.event_id == ^event_id and r.status == :waitlisted)
      |> Repo.aggregate(:count, :id)

    attended =
      from(r in Registration, where: r.event_id == ^event_id and r.attended == true)
      |> Repo.aggregate(:count, :id)

    occupancy =
      if event.max_seats > 0, do: Float.round(regs / event.max_seats * 100, 2), else: 0.0

    %{
      event: event,
      total_registrations: regs,
      waitlisted: waitlisted,
      total_attended: attended,
      remaining_seats: max(0, event.max_seats - regs),
      occupancy_rate: occupancy
    }
  end

  def search_events(term) when is_binary(term),
    do: Repo.search_events(term) |> Repo.all() |> Repo.preload([:speaker])

  def search_events(_), do: {:error, :invalid_query}

  defp filter_status(q, nil), do: q
  defp filter_status(q, status), do: where(q, [e], e.status == ^status)
  defp filter_speaker(q, nil), do: q
  defp filter_speaker(q, id), do: where(q, [e], e.speaker_id == ^id)
  defp filter_upcoming(q, true), do: where(q, [e], e.date > ^DateTime.utc_now())
  defp filter_upcoming(q, _), do: q
  defp order_events(q, {:date, :asc}), do: order_by(q, [e], asc: e.date)
  defp order_events(q, {:date, :desc}), do: order_by(q, [e], desc: e.date)
  defp order_events(q, {:title, :asc}), do: order_by(q, [e], asc: e.title)
  defp order_events(q, _), do: order_by(q, [e], asc: e.date)
  defp paginate(q, nil, _), do: q

  defp paginate(q, page, per_page) do
    offset = (max(page, 1) - 1) * per_page
    q |> limit(^per_page) |> offset(^offset)
  end
end
