defmodule EventManagerWeb.EventChatLive do
  @moduledoc """
  LiveView para a funcionalidade de Chat ao Vivo.

  Representa a principal e mais chamativa funcionalidade interativa do sistema, processando o DOM no lado do servidor via WebSockets.
  Sempre que um usuário envia uma mensagem, o servidor atualiza o estado local e empurra apenas o diff HTML resultante para os clientes, economizando banda e simplificando o frontend em JS.
  Integra-se com o `EventManager.Services` para armazenar histórico e utiliza o Phoenix.PubSub para coordenar eventos assíncronos.
  """
  use EventManagerWeb, :live_view

  alias EventManagerWeb.Presence

  @impl true
  def mount(%{"id" => event_id}, _session, socket) do
    current_user = socket.assigns.current_user
    presence_topic = "event_chat:#{event_id}"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(EventManager.PubSub, presence_topic)

      Presence.track(self(), presence_topic, to_string(current_user.id), %{
        online_at: DateTime.utc_now() |> DateTime.to_iso8601()
      })
    end

    messages_raw = EventManager.Services.list_event_chat_messages(event_id, limit: 100)

    {messages, last_date} =
      Enum.reduce(messages_raw, {[], nil}, fn msg, {acc, last_date} ->
        msg_date = NaiveDateTime.to_date(msg.sent_at)

        formatted_msg = %{
          id: "msg-#{msg.id}",
          type: :message,
          user_id: msg.user_id,
          message: msg.message,
          user_name: if(msg.user, do: msg.user.name, else: "Anon"),
          avatar_path: if(msg.user, do: msg.user.avatar_path, else: nil),
          sent_at: msg.sent_at,
          is_question: msg.is_question,
          is_answered: msg.is_answered,
          file_url: Map.get(msg, :file_url),
          file_name: Map.get(msg, :file_name),
          file_type: Map.get(msg, :file_type)
        }

        if last_date != msg_date do
          divider = %{
            id: "date-#{Date.to_string(msg_date)}",
            type: :date_divider,
            date: msg_date
          }

          {[formatted_msg, divider | acc], msg_date}
        else
          {[formatted_msg | acc], last_date}
        end
      end)

    messages = Enum.reverse(messages)
    all_events = EventManager.Core.list_events()

    {:ok,
     socket
     |> assign(
       event: EventManager.Core.get_event!(event_id),
       all_events: all_events,
       message_input: "",
       is_question: false,
       current_user: current_user,
       last_message_date: last_date,
       presence_topic: presence_topic,
       online_users: list_online_users(presence_topic)
     )
     |> allow_upload(:chat_file,
       accept: ~w(.jpg .jpeg .png .pdf),
       max_entries: 1,
       max_file_size: 10_000_000
     )
     |> stream(:messages, messages)}
  end

  @impl true
  def handle_event("validate", %{"message" => msg}, socket) do
    {:noreply, assign(socket, message_input: msg)}
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("send_message", params, socket) do
    msg = params["message"]
    is_q = params["is_question"] == "true"

    uploaded_files =
      consume_uploaded_entries(socket, :chat_file, fn %{path: path}, entry ->
        dest_dir = "priv/static/uploads/chat"
        File.mkdir_p!(dest_dir)
        ext = Path.extname(entry.client_name)
        file_name = "#{System.unique_integer([:positive])}-#{entry.uuid}#{ext}"
        dest = Path.join(dest_dir, file_name)
        File.cp!(path, dest)

        {:ok,
         %{url: "/uploads/chat/#{file_name}", name: entry.client_name, type: entry.client_type}}
      end)

    file_data = List.first(uploaded_files)

    if (msg && String.trim(msg) != "") or not is_nil(file_data) do
      attrs = %{
        event_id: socket.assigns.event.id,
        user_id: socket.assigns.current_user.id,
        message: msg,
        is_question: is_q
      }

      attrs =
        if file_data do
          Map.merge(attrs, %{
            file_url: file_data.url,
            file_name: file_data.name,
            file_type: file_data.type
          })
        else
          attrs
        end

      case EventManager.Services.create_chat_message(attrs) do
        {:ok, _new_msg} ->
          IO.puts(">>> INSERT SUCCESS")
          {:noreply, assign(socket, message_input: "", is_question: false)}

        {:error, cs} ->
          IO.puts(">>> INSERT ERROR: #{inspect(cs.errors)}")
          errors = inspect(cs.errors)
          {:noreply, put_flash(socket, :error, "Falha ao enviar mensagem: #{errors}")}
      end
    else
      IO.puts(">>> MESSAGE WAS EMPTY")
      {:noreply, assign(socket, message_input: "", is_question: false)}
    end
  end

  @impl true
  def handle_event("toggle_question", _params, socket),
    do: {:noreply, update(socket, :is_question, &(!&1))}

  @impl true
  def handle_event("mark_answered", %{"message_id" => msg_id}, socket) do
    if socket.assigns.current_user.role in [:admin, :speaker] do
      EventManager.Services.mark_question_answered(msg_id)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "new_message", payload: msg}, socket) do
    msg_date = NaiveDateTime.to_date(msg.sent_at)
    last_date = socket.assigns.last_message_date

    formatted_msg = %{
      id: "msg-#{msg.id}",
      type: :message,
      user_id: msg.user_id,
      message: msg.message,
      user_name: msg.user_name,
      avatar_path: msg.avatar_path,
      sent_at: msg.sent_at,
      is_question: msg.is_question,
      is_answered: msg.is_answered,
      file_url: Map.get(msg, :file_url),
      file_name: Map.get(msg, :file_name),
      file_type: Map.get(msg, :file_type)
    }

    if last_date != msg_date do
      divider = %{
        id: "date-#{Date.to_string(msg_date)}",
        type: :date_divider,
        date: msg_date
      }

      {:noreply,
       socket
       |> assign(last_message_date: msg_date)
       |> stream_insert(:messages, divider)
       |> stream_insert(:messages, formatted_msg)}
    else
      {:noreply, stream_insert(socket, :messages, formatted_msg)}
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, online_users: list_online_users(socket.assigns.presence_topic))}
  end

  defp list_online_users(topic) do
    topic
    |> Presence.list()
    |> Enum.map(fn {_id, %{user: user, metas: metas}} ->
      %{user: user, metas: metas}
    end)
    |> Enum.reject(&is_nil(&1.user))
    |> Enum.sort_by(&String.downcase(&1.user.name || ""))
  end
end
