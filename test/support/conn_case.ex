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
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
