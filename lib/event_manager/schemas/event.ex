defmodule EventManager.Schemas.Event do
  @moduledoc """
  Event schema for academic events management.
  Supports seat limits, speaker assignment, and status tracking.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @statuses ~w(draft published ongoing completed cancelled)a

  schema "events" do
    field :title, :string
    field :description, :string
    field :date, :utc_datetime
    field :duration_minutes, :integer, default: 60
    field :location, :string
    field :max_seats, :integer
    field :status, Ecto.Enum, values: @statuses, default: :published
    field :image_url, :string
    field :is_online, :boolean, default: false
    field :online_url, :string
    field :tags, {:array, :string}, default: []

    belongs_to :speaker, EventManager.Schemas.User
    has_many :registrations, EventManager.Schemas.Registration, on_delete: :delete_all
    has_many :chat_messages, EventManager.Schemas.ChatMessage, on_delete: :delete_all
    has_many :certificates, EventManager.Schemas.Certificate, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :title,
      :description,
      :date,
      :duration_minutes,
      :location,
      :max_seats,
      :status,
      :speaker_id,
      :image_url,
      :is_online,
      :online_url,
      :tags
    ])
    |> validate_required([:title, :description, :date, :location, :max_seats, :speaker_id])
    |> validate_number(:max_seats, greater_than: 0, less_than: 10_000)
    |> validate_number(:duration_minutes, greater_than: 0, less_than: 1440)
    |> validate_length(:title, min: 5, max: 200)
    |> validate_length(:description, max: 5000)
    |> validate_future_date()
    |> validate_online_url_if_online()
    |> foreign_key_constraint(:speaker_id)
  end

  @doc "Changeset for publishing an event"
  def publish_changeset(event) do
    event
    |> change(status: :published)
    |> validate_inclusion(:status, [:published])
  end

  @doc "Changeset for cancelling an event"
  def cancel_changeset(event) do
    change(event, status: :cancelled)
  end

  defp validate_future_date(changeset) do
    case get_change(changeset, :date) do
      nil -> changeset
      date ->
        if DateTime.compare(date, DateTime.utc_now()) == :lt do
          add_error(changeset, :date, "deve ser uma data futura")
        else
          changeset
        end
    end
  end

  defp validate_online_url_if_online(changeset) do
    case get_change(changeset, :is_online) do
      true ->
        case get_change(changeset, :online_url) do
          nil -> add_error(changeset, :online_url, "é obrigatório para eventos online")
          "" -> add_error(changeset, :online_url, "é obrigatório para eventos online")
          _ -> changeset
        end
      _ -> changeset
    end
  end

  @doc "Returns all available statuses"
  def statuses, do: @statuses

  @doc "Counts current confirmed registrations"
  def registration_count(%__MODULE__{id: event_id}) do
    from(r in EventManager.Schemas.Registration, where: r.event_id == ^event_id and r.status == :confirmed)
    |> EventManager.Repo.aggregate(:count, :id)
  end

  @doc "Checks if event has available seats"
  def has_available_seats?(%__MODULE__{id: id, max_seats: max_seats}) do
    registration_count(%__MODULE__{id: id}) < max_seats
  end

  @doc "Returns remaining seats count"
  def remaining_seats(%__MODULE__{} = event) do
    max(0, event.max_seats - registration_count(event))
  end

  @doc "Checks if event is upcoming"
  def upcoming?(%__MODULE__{date: date}) do
    DateTime.compare(date, DateTime.utc_now()) == :gt
  end

  @doc "Checks if user can register"
  def can_register?(%__MODULE__{status: :published} = event) do
    upcoming?(event) and has_available_seats?(event)
  end
  def can_register?(_), do: false
end
