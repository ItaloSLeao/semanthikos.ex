defmodule EventManagerWeb.HomeLive do
  @moduledoc """
  Módulo `EventManagerWeb.HomeLive`.

  Faz parte da estrutura base do Event Manager, localizado em `event_manager_web/live/home_live.ex`.
  Define lógicas, componentes ou rotas específicas dessa camada.
  Para detalhes mais profundos, consulte a documentação da arquitetura central (`EventManager.Core` e `EventManagerWeb.Router`).
  """
  use EventManagerWeb, :live_view

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    my_registrations = EventManager.Core.list_user_registrations(user.id)
    my_events = Enum.map(my_registrations, & &1.event)

    my_certificates = EventManager.Services.list_user_certificates(user.id)

    total_hours =
      Enum.reduce(my_certificates, 0, fn cert, acc ->
        duration =
          if Map.has_key?(cert, :event) && cert.event,
            do: Map.get(cert.event, :duration_minutes, 240) || 240,
            else: 240

        hours = round(duration / 60)
        acc + hours
      end)

    next_event =
      my_events
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(& &1.date, {:asc, Date})
      |> Enum.find(fn e -> Date.compare(e.date, Date.utc_today()) in [:gt, :eq] end)

    all_events = EventManager.Core.list_events()

    explore_events =
      all_events
      |> Enum.reject(fn e ->
        Enum.any?(my_events, fn my_e -> my_e && my_e.id == e.id end)
      end)
      |> Enum.take(4)

    {:ok,
     assign(socket,
       my_events: my_events,
       my_certificates: my_certificates,
       total_hours: total_hours,
       next_event: next_event,
       explore_events: explore_events,
       page_title: "Início"
     )}
  end
end
