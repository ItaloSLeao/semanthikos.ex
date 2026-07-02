defmodule EventManager.Schemas.ChatMessage do
  @moduledoc """
  Esquema Ecto para Mensagens do Chat.

  Mapeia a tabela `chat_messages` no banco de dados. Representa instâncias individuais de mensagens enviadas no chat ao vivo.
  Define as relações (quem enviou, de qual evento pertence) e lógicas de validação (cast) de dados antes de serem inseridos no BD.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    field :message, :string
    field :sent_at, :utc_datetime
    field :is_question, :boolean, default: false
    field :is_answered, :boolean, default: false
    field :file_url, :string
    field :file_name, :string
    field :file_type, :string

    belongs_to :event, EventManager.Schemas.Event
    belongs_to :user, EventManager.Schemas.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [
      :message,
      :event_id,
      :user_id,
      :is_question,
      :is_answered,
      :file_url,
      :file_name,
      :file_type
    ])
    |> validate_required([:event_id, :user_id])
    |> validate_message_or_file()
    |> validate_length(:message, max: 1000)
    |> default_sent_at()
    |> foreign_key_constraint(:event_id)
    |> foreign_key_constraint(:user_id)
  end

  defp validate_message_or_file(changeset) do
    message = get_field(changeset, :message)
    file_url = get_field(changeset, :file_url)

    if (is_nil(message) or String.trim(message) == "") and is_nil(file_url) do
      add_error(changeset, :message, "can't be blank if no file is attached")
    else
      changeset
    end
  end

  defp default_sent_at(changeset) do
    if get_field(changeset, :sent_at) do
      changeset
    else
      put_change(changeset, :sent_at, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end

  @doc "Changeset for marking a question as answered"
  def answer_changeset(chat_message) do
    change(chat_message, is_answered: true)
  end
end
