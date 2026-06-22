defmodule EventManagerWeb.EventChatLiveTest do
  use EventManagerWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "sends a chat message", %{conn: conn} do
    user = EventManager.Repo.insert!(%EventManager.Schemas.User{
      email: "test@test.com", hashed_password: "abc", name: "Test",
      role: :student, cpf: "123", birth_date: ~D[2000-01-01]
    })
    event = EventManager.Repo.insert!(%EventManager.Schemas.Event{
      title: "Test Event", description: "Desc", location: "Loc",
      date: ~U[2026-01-01 00:00:00Z], max_seats: 10, speaker_id: user.id
    })

    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/events/#{event.id}/chat")

    view |> element("form#chat-form") |> render_submit(%{"message" => "Hello E2E Test"})
    assert render(view) =~ "Hello E2E Test"
  end
end
