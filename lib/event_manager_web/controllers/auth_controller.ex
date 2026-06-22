defmodule EventManagerWeb.AuthController do
  @moduledoc """
  Controller for authentication operations (login, logout, registration, password reset, settings).
  Consolidates previously separate user controllers.
  """
  use EventManagerWeb, :controller

  alias EventManagerWeb.UserAuth

  # Aplica tela cheia (sem navbar) para login E registro
  plug :put_layout, [html: false] when action in [:new_session, :create_session, :new_registration, :create_registration]

  # --- Registration ---
  def new_registration(conn, _params) do
    changeset = EventManager.Schemas.User.registration_changeset(%EventManager.Schemas.User{}, %{})
    render(conn, "registration_new.html", changeset: changeset)
  end

  def create_registration(conn, %{"user" => user_params}) do
    case EventManager.Core.register_user(user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Conta criada com sucesso! Faça login para continuar.")
        |> redirect(to: ~p"/users/log_in")

      {:error, changeset} ->
        render(conn, "registration_new.html", changeset: changeset)
    end
  end

  def new_session(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/events")
    else
      conn
      |> put_layout(html: false)
      |> render("session_new.html", error_message: nil)
    end
  end

  def create_session(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = EventManager.Core.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Bem-vindo(a), #{user.name}!")
      |> UserAuth.log_in_user(user)
    else
      render(conn, "session_new.html", error_message: "Email ou senha inválidos")
    end
  end

  def delete_session(conn, _params) do
    conn |> UserAuth.log_out_user() |> redirect(to: ~p"/")
  end

  # --- Password Reset ---
  def new_reset_password(conn, _params), do: render(conn, "reset_password_new.html")

  def create_reset_password(conn, %{"user" => %{"email" => email}}) do
    if user = EventManager.Core.get_user_by_email(email) do
      EventManager.Core.deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
    end

    conn
    |> put_flash(:info, "Se o email existir, você receberá instruções para redefinir a senha.")
    |> redirect(to: ~p"/")
  end

  def edit_reset_password(conn, %{"token" => token}) do
    if EventManager.Core.get_user_by_reset_password_token(token) do
      render(conn, "reset_password_edit.html", token: token)
    else
      conn
      |> put_flash(:error, "Link de redefinição de senha inválido ou expirado.")
      |> redirect(to: ~p"/")
    end
  end

  def update_reset_password(conn, %{"token" => token, "user" => user_params}) do
    user = EventManager.Core.get_user_by_reset_password_token(token)

    if user do
      case EventManager.Core.reset_user_password(user, user_params) do
        {:ok, _} ->
          conn
          |> put_flash(:info, "Senha redefinida com sucesso. Faça login.")
          |> redirect(to: ~p"/users/log_in")

        {:error, _} ->
          render(conn, "reset_password_edit.html", token: token)
      end
    else
      conn
      |> put_flash(:error, "Link de redefinição de senha inválido ou expirado.")
      |> redirect(to: ~p"/")
    end
  end

  # --- User Settings ---
  def edit_settings(conn, _params) do
    user = conn.assigns.current_user
    render(conn, "settings_edit.html", user: user)
  end

  def update_settings(conn, %{"user" => user_params} = params) do
    user = conn.assigns.current_user

    user_params = if upload = params["avatar"] do
      upload_path = Path.join(:code.priv_dir(:event_manager), "static/uploads")
      File.mkdir_p!(upload_path)

      filename = "#{user.id}-#{System.unique_integer([:positive])}#{Path.extname(upload.filename)}"
      dest = Path.join(upload_path, filename)
      File.cp!(upload.path, dest)
      Map.put(user_params, "avatar_path", "/uploads/#{filename}")
    else
      user_params
    end

    case EventManager.Core.update_user_profile(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Perfil atualizado com sucesso.")
        |> redirect(to: ~p"/users/settings")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Erro ao atualizar perfil.")
        |> render("settings_edit.html", user: user)
    end
  end

  def update_password(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case EventManager.Core.update_user_password(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Senha atualizada com sucesso.")
        |> redirect(to: ~p"/users/settings")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Erro ao atualizar senha. Verifique a senha atual.")
        |> render("settings_edit.html", user: user)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    if EventManager.Core.confirm_user(token) do
      conn
      |> put_flash(:info, "Email confirmado com sucesso.")
      |> redirect(to: ~p"/users/settings")
    else
      conn
      |> put_flash(:error, "Link de confirmação inválido ou expirado.")
      |> redirect(to: ~p"/users/settings")
    end
  end
end
