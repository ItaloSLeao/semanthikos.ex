defmodule EventManager.DataCase do
  @moduledoc """
  Test case for data layer tests.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      alias EventManager.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import EventManager.DataCase
    end
  end

  setup tags do
    EventManager.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(EventManager.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  def error_on(changeset, field) do
    Keyword.get(changeset.errors, field)
  end

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end