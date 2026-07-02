defmodule EventManagerWeb.ErrorHTML do
  @moduledoc """
  Error HTML rendering module.
  Handles 4xx and 5xx error responses.
  """
  use EventManagerWeb, :html

  def render("404.html", _assigns) do
    "Página não encontrada"
  end

  def render("500.html", _assigns) do
    "Erro interno do servidor"
  end

  def render("403.html", _assigns) do
    "Acesso negado"
  end

  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
