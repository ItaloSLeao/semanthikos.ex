defmodule EventManager.Fixtures do
  @moduledoc """
  Fixtures for testing.
  """
  
  

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "Password@123"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      name: "Test User",
      password: valid_user_password(),
      role: :student
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> EventManager.Core.register_user()

    user
  end

  def admin_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Map.put(:role, :admin)
      |> valid_user_attributes()
      |> EventManager.Core.register_user()

    user
  end

  def speaker_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Map.put(:role, :speaker)
      |> valid_user_attributes()
      |> EventManager.Core.register_user()

    user
  end

  def valid_event_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      title: "Test Event #{System.unique_integer()}",
      description: "Test event description",
      date: DateTime.utc_now() |> DateTime.add(7 * 24 * 60 * 60, :second),
      duration_minutes: 60,
      location: "Test Location",
      max_seats: 50,
      status: :published
    })
  end

  def event_fixture(attrs \\ %{}) do
    speaker = speaker_fixture()

    {:ok, event} =
      attrs
      |> valid_event_attributes()
      |> Map.put(:speaker_id, speaker.id)
      |> EventManager.Core.create_event()

    event
  end

  def registration_fixture(user \\ nil, event \\ nil) do
    user = user || user_fixture()
    event = event || event_fixture()

    {:ok, registration} = EventManager.Core.register_for_event(event.id, user.id)
    registration
  end
end