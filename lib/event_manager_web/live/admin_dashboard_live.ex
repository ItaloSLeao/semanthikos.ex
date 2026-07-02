defmodule EventManagerWeb.AdminDashboardLive do
  @moduledoc """
  Dashboard em tempo real para os Administradores, via Phoenix LiveView.

  Exibe métricas, estado do sistema e eventos de forma reativa, sem a necessidade de F5 pelo usuário.
  Mantém uma conexão WebSocket ativa.
  """
  use EventManagerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(EventManager.PubSub, "admin_dashboard")
      :timer.send_interval(30000, :refresh)
    end

    current_user = socket.assigns.current_user
    stats = get_dashboard_stats()

    {:ok, assign(socket, stats: stats, current_user: current_user)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    stats = get_dashboard_stats()
    {:noreply, assign(socket, stats: stats)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    stats = get_dashboard_stats()
    {:noreply, assign(socket, stats: stats)}
  end

  defp get_dashboard_stats do
    %{
      system: EventManager.Services.get_system_stats(),
      occupancy: EventManager.Services.get_occupancy_report(limit: 5),
      participation: EventManager.Services.get_participation_by_course() |> Enum.take(5)
    }
  end
end
