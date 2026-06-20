defmodule EventManagerWeb.UserAuth do
  @moduledoc """
  Authentication and authorization plug for protecting routes.
  Implements role-based access control (RBAC).
  """
  use EventManagerWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias EventManager.Core
  alias EventManager.Schemas.User

  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = if user_token, do: EventManager.Core.get_user_by_session_token(user_token), else: nil
    assign(conn, :current_user, user)
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "Você precisa estar logado para acessar esta página.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  def require_admin(conn, _opts) do
    user = conn.assigns[:current_user]
    if user && User.admin?(user) do
      conn
    else
      conn |> put_flash(:error, "Acesso restrito a administradores.") |> redirect(to: ~p"/") |> halt()
    end
  end

  def require_speaker(conn, _opts) do
    user = conn.assigns[:current_user]
    if user && (User.admin?(user) || User.speaker?(user)) do
      conn
    else
      conn |> put_flash(:error, "Acesso restrito.") |> redirect(to: ~p"/") |> halt()
    end
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: ["user_token"])
      if token = conn.cookies["user_token"] do
        {token, put_session(conn, :user_token, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc "Logs user in"
  def log_in_user(conn, user, params \\ %{}) do
    token = Core.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "user_sessions:#{user.id}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: user_return_to || ~p"/events")
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, "user_token", token, sign: true, max_age: 60 * 60 * 24 * 60)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params), do: conn

  @doc "Logs user out"
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Core.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      EventManagerWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie("user_token")
    |> redirect(to: ~p"/users/log_in")
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  def on_mount(:mount_current_user, _params, session, socket) do
    case session do
      %{"user_token" => user_token} ->
        {:cont, Phoenix.Component.assign(socket, :current_user, EventManager.Core.get_user_by_session_token(user_token))}
      _ ->
        {:cont, Phoenix.Component.assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    case session do
      %{"user_token" => user_token} ->
        user = EventManager.Core.get_user_by_session_token(user_token)
        if user do
          {:cont, Phoenix.Component.assign(socket, :current_user, user)}
        else
          {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/users/log_in")}
        end
      _ ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/users/log_in")}
    end
  end
end
