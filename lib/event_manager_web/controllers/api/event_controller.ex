defmodule EventManagerWeb.Api.EventController do
  @moduledoc """
  Módulo `EventManagerWeb.Api.EventController`.

  Faz parte da estrutura base do Event Manager, localizado em `event_manager_web/controllers/api/event_controller.ex`.
  Define lógicas, componentes ou rotas específicas dessa camada.
  Para detalhes mais profundos, consulte a documentação da arquitetura central (`EventManager.Core` e `EventManagerWeb.Router`).
  """
  use EventManagerWeb, :controller

  def index(conn, params) do
    events = EventManager.Core.list_events(params)
    render(conn, :index, events: events)
  end

  def show(conn, %{"id" => id}) do
    event = EventManager.Core.get_event!(id)
    render(conn, :show, event: event)
  end

  def stats(conn, %{"id" => id}) do
    stats = EventManager.Core.get_event_stats(id)
    json(conn, stats)
  end
end
