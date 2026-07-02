defmodule EventManagerWeb.ErrorJSON do
  @moduledoc """
  Error JSON rendering module.
  Handles API error responses.
  """
  def render("404.json", _assigns) do
    %{errors: %{detail: "Não encontrado"}}
  end

  def render("500.json", _assigns) do
    %{errors: %{detail: "Erro interno do servidor"}}
  end

  def render("403.json", _assigns) do
    %{errors: %{detail: "Acesso negado"}}
  end

  def render("422.json", %{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end

  def template_not_found(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end

  defp translate_error({msg, opts}) do
    Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end
end
