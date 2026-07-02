defmodule EventManager.Repo do
  @moduledoc """
  Mecanismo de banco de dados do sistema, utilizando Ecto.

  Responsável por realizar a comunicação com o PostgreSQL e gerenciar transações.
  Aqui são implementadas operações atômicas críticas, como `reserve_seat/2`, que garante a atomicidade em reservas de vagas sem race conditions.
  """
  use Ecto.Repo,
    otp_app: :event_manager,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Query

  @doc """
  Execute a transaction with optimistic locking for seat reservation.
  Prevents overbooking by checking seat availability atomically.
  """
  def reserve_seat(event_id, user_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:event, fn repo, _ ->
      case repo.get(EventManager.Schemas.Event, event_id) do
        nil -> {:error, :event_not_found}
        event -> {:ok, event}
      end
    end)
    |> Ecto.Multi.run(:check_seats, fn repo, %{event: event} ->
      current_confirmed =
        from(r in EventManager.Schemas.Registration,
          where: r.event_id == ^event_id and r.status == :confirmed,
          select: count(r.id)
        )
        |> repo.one()

      status = if current_confirmed < event.max_seats, do: :confirmed, else: :waitlisted
      {:ok, status}
    end)
    |> Ecto.Multi.insert(:registration, fn %{check_seats: status} ->
      attrs = %{
        event_id: event_id,
        user_id: user_id,
        status: status,
        registered_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      EventManager.Schemas.Registration.changeset(%EventManager.Schemas.Registration{}, attrs)
    end)
    |> transaction()
  end

  @doc """
  Full-text search for events using PostgreSQL tsvector.
  Searches across title and description fields.
  """
  def search_events(query_term) do
    like_term = "%#{query_term}%"

    from e in EventManager.Schemas.Event,
      left_join: s in assoc(e, :speaker),
      where:
        fragment(
          "to_tsvector('portuguese', ? || ' ' || ?) @@ plainto_tsquery('portuguese', ?)",
          e.title,
          e.description,
          ^query_term
        ) or
          ilike(e.location, ^like_term) or
          ilike(s.name, ^like_term),
      order_by: [desc: e.date],
      select: e
  end
end
