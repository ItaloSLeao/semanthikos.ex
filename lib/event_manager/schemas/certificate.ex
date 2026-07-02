defmodule EventManager.Schemas.Certificate do
  @moduledoc """
  Certificate schema for event participation.
  Generates unique certificate numbers and stores PDF data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "certificates" do
    field :certificate_number, :string

    field :certificate_type, Ecto.Enum,
      values: [:participation, :speaker, :organizer],
      default: :participation

    field :generated_at, :utc_datetime
    field :pdf_data, :binary
    field :verified, :boolean, default: false

    belongs_to :user, EventManager.Schemas.User
    belongs_to :event, EventManager.Schemas.Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(certificate, attrs) do
    certificate
    |> cast(attrs, [:user_id, :event_id, :certificate_type, :pdf_data, :verified])
    |> validate_required([:user_id, :event_id])
    |> default_generated_at()
    |> generate_certificate_number()
    |> unique_constraint(:certificate_number)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:event_id)
  end

  defp default_generated_at(changeset) do
    if get_field(changeset, :generated_at) do
      changeset
    else
      put_change(changeset, :generated_at, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end

  defp generate_certificate_number(changeset) do
    if get_field(changeset, :certificate_number) do
      changeset
    else
      user_id = get_field(changeset, :user_id)
      event_id = get_field(changeset, :event_id)
      timestamp = DateTime.utc_now() |> DateTime.to_unix()
      number = "CERT-#{event_id}-#{user_id}-#{timestamp}"
      put_change(changeset, :certificate_number, number)
    end
  end
end
