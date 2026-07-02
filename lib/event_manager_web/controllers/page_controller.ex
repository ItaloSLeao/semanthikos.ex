defmodule EventManagerWeb.PageController do
  @moduledoc """
  Home page controller for the application.
  """
  use EventManagerWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/events")
    else
      redirect(conn, to: ~p"/users/log_in")
    end
  end
end
