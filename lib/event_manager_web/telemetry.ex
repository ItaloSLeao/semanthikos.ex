defmodule EventManagerWeb.Telemetry do
  @moduledoc """
  Telemetry module for collecting metrics and monitoring application health.
  """
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("event_manager.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "Total database query time"
      ),
      summary("event_manager.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "Database query decode time"
      ),
      summary("event_manager.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "Database query execution time"
      ),
      summary("event_manager.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "Database query queue time"
      ),
      summary("event_manager.repo.query.idle_time",
        unit: {:native, :millisecond},
        description: "Database query idle time"
      ),

      # VM Metrics
      last_value("vm.memory.total", unit: {:byte, :kilobyte}),
      last_value("vm.memory.processes", unit: {:byte, :kilobyte}),
      last_value("vm.memory.system", unit: {:byte, :kilobyte}),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.total_run_queue_lengths.io"),

      # Custom Business Metrics
      counter("event_manager.events.created", tags: [:status]),
      counter("event_manager.registrations.created"),
      counter("event_manager.certificates.generated"),
      summary("event_manager.chat.messages.count")
    ]
  end

  defp periodic_measurements do
    [
      {__MODULE__, :process_count, []},
      {__MODULE__, :event_stats, []}
    ]
  end

  def process_count do
    :telemetry.execute([:vm, :processes], %{count: Process.list() |> length()})
  end

  def event_stats do
    events = EventManager.Core.list_events()

    registrations =
      (length(events) > 0 && events |> Enum.map(&(&1.registrations |> length)) |> Enum.sum()) || 0

    :telemetry.execute(
      [:event_manager, :stats],
      %{
        events_count: length(events),
        registrations_count: registrations
      }
    )
  end
end
