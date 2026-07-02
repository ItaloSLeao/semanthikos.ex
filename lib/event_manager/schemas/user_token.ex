defmodule EventManager.Schemas.UserToken do
  @moduledoc """
  UserToken schema for session and email tokens.
  """
  use Ecto.Schema
  import Ecto.Query

  @hash_algorithm :sha256
  @rand_size 32

  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, EventManager.Schemas.User

    timestamps(updated_at: false)
  end

  @doc "Builds a session token for the user"
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %__MODULE__{token: hashed_token, context: "session", user_id: user.id}}
  end

  @doc "Verifies session token query"
  def verify_session_token_query(token) do
    query =
      from t in __MODULE__,
        where: t.context == "session",
        where:
          t.token == ^:crypto.hash(@hash_algorithm, Base.url_decode64!(token, padding: false)),
        join: user in assoc(t, :user),
        select: user

    query
  end

  @doc "Builds an email token for confirmation or password reset"
  def build_email_token(user, context) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %__MODULE__{
       token: hashed_token,
       context: context,
       user_id: user.id,
       sent_to: user.email
     }}
  end

  @doc "Verifies email token query"
  def verify_email_token_query(token, context) do
    query =
      from t in __MODULE__,
        where: t.context == ^context,
        where:
          t.token == ^:crypto.hash(@hash_algorithm, Base.url_decode64!(token, padding: false)),
        where: t.inserted_at > ago(24, "hour")

    from t in query, join: user in assoc(t, :user), select: user
  end

  @doc "Query for deleting all tokens for a user in a context"
  def delete_all_for_user(user, context) do
    from(t in __MODULE__, where: t.user_id == ^user.id and t.context == ^context)
    |> EventManager.Repo.delete_all()
  end

  @doc "Query for all tokens by user and contexts"
  def by_user_and_contexts_query(user, :all) do
    from t in __MODULE__, where: t.user_id == ^user.id
  end

  def by_user_and_contexts_query(user, contexts) when is_list(contexts) do
    from t in __MODULE__, where: t.user_id == ^user.id and t.context in ^contexts
  end

  @doc "Query for token by token and context"
  def by_token_and_context_query(token, context) do
    from t in __MODULE__,
      where: t.context == ^context,
      where: t.token == ^:crypto.hash(@hash_algorithm, Base.url_decode64!(token, padding: false))
  end
end
