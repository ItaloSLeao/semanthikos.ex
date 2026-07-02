defmodule EventManager.Schemas.Registration do
  @moduledoc """
  Registration schema for event participation.
  Tracks user event registrations with attendance status.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "registrations" do
    field :registered_at, :utc_datetime
    field :attended, :boolean, default: false
    field :attendance_marked_at, :utc_datetime
    field :notes, :string
    field :status, Ecto.Enum, values: [:confirmed, :waitlisted, :cancelled], default: :confirmed

    belongs_to :user, EventManager.Schemas.User
    belongs_to :event, EventManager.Schemas.Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(registration, attrs) do
    registration
    |> cast(attrs, [
      :user_id,
      :event_id,
      :attended,
      :attendance_marked_at,
      :notes,
      :registered_at,
      :status
    ])
    |> validate_required([:user_id, :event_id])
    |> default_registered_at()
    |> unique_constraint([:user_id, :event_id], name: :registrations_user_event_index)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:event_id)
  end

  defp default_registered_at(changeset) do
    if get_field(changeset, :registered_at) do
      changeset
    else
      put_change(changeset, :registered_at, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end

  @doc "Changeset for marking attendance"
  def attendance_changeset(registration, attrs) do
    registration
    |> cast(attrs, [:attended])
    |> validate_required([:attended])
    |> put_change(:attendance_marked_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc "Changeset for cancelling a registration"
  def cancel_changeset(registration) do
    change(registration, status: :cancelled)
  end

  @doc "Checks if user can receive certificate"
  def can_receive_certificate?(%__MODULE__{attended: true}), do: true
  def can_receive_certificate?(_), do: false
end
