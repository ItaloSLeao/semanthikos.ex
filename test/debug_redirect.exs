defmodule DebugRedirect do
  use ExUnit.Case
  use EventManagerWeb.ConnCase

  test "debug redirect", %{conn: conn} do
    user = EventManager.Repo.insert!(%EventManager.Schemas.User{
      email: "debug2@test.com", hashed_password: "abc", name: "Test",
      role: :student, cpf: "123", birth_date: ~D[2000-01-01]
    })
    event = EventManager.Repo.insert!(%EventManager.Schemas.Event{
      title: "Test Event", description: "Desc", location: "Loc",
      date: ~U[2026-01-01 00:00:00Z], max_seats: 10, speaker_id: user.id
    })

    conn = log_in_user(conn, user)
    
    conn = get(conn, "/events/#{event.id}/chat")
    IO.puts("STATUS: #{conn.status}")
    if conn.status in [301, 302] do
      IO.puts("REDIRECT TO: #{inspect get_resp_header(conn, "location")}")
    end
  end
end
