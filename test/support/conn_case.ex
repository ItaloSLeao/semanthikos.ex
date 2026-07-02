defmodule EventManagerWeb.ConnCase do
  @moduledoc """
  Test case for controller and endpoint tests.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint EventManagerWeb.Endpoint

      use EventManagerWeb, :verified_routes
      import Plug.Conn
      import Phoenix.ConnTest
      import EventManagerWeb.ConnCase
    end
  end

  setup tags do
    EventManager.DataCase.setup_sandbox(tags)

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("x-forwarded-proto", "https")

    {:ok, conn: conn}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    {token, user_token} = EventManager.Schemas.UserToken.build_session_token(user)
    EventManager.Repo.insert!(user_token)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
