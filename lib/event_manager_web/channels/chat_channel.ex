defmodule EventManagerWeb.ChatChannel do
  @moduledoc """
  Canal de Chat em Tempo Real (Phoenix Channels).

  Este módulo define o funcionamento do WebSocket para as salas de chat padrão (não-LiveView).
  Ele permite comunicação bidirecional de baixa latência e utiliza o PubSub do Phoenix para distribuir a mensagem instantaneamente a todos os clientes conectados no mesmo tópico (ex: `chat:event_id`).
  Funciona escutando eventos como `"new_msg"` e transmitindo via `broadcast!`.
  """
  use EventManagerWeb, :channel

  @impl true
  def join("event_chat:" <> event_id, _params, socket) do
    if authorized?(socket, event_id) do
      messages = EventManager.Services.list_event_chat_messages(event_id, limit: 50)
      {:ok, %{messages: format_messages(messages)}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("new_message", %{"message" => message, "is_question" => is_question}, socket) do
    "event_chat:" <> event_id = socket.topic
    user = socket.assigns.current_user

    case EventManager.Services.create_chat_message(%{
           event_id: event_id,
           user_id: user.id,
           message: message,
           is_question: is_question
         }) do
      {:ok, chat_message} ->
        broadcast_from!(socket, "new_message", %{
          id: chat_message.id,
          message: chat_message.message,
          user_name: user.name,
          is_question: chat_message.is_question,
          sent_at: chat_message.sent_at
        })

        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: format_errors(changeset)}}, socket}
    end
  end

  @impl true
  def handle_in("mark_answered", %{"message_id" => message_id}, socket) do
    user = socket.assigns.current_user

    if user.role in [:admin, :speaker] do
      {:ok, _} = EventManager.Services.mark_question_answered(message_id)
      broadcast!(socket, "question_answered", %{message_id: message_id})
      {:reply, :ok, socket}
    else
      {:reply, {:error, %{reason: "unauthorized"}}, socket}
    end
  end

  defp authorized?(socket, _event_id) do
    user = socket.assigns[:current_user]
    user != nil
  end

  defp format_messages(messages) do
    Enum.map(messages, fn m ->
      %{
        id: m.id,
        message: m.message,
        user_name: m.user && m.user.name,
        is_question: m.is_question,
        is_answered: m.is_answered,
        sent_at: m.sent_at
      }
    end)
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
