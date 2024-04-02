defmodule OsInfoMeasurer.PortServer do
  use GenServer

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_measure() do
    GenServer.call(__MODULE__, :start_measure)
  end

  def stop_measure() do
    GenServer.call(__MODULE__, :stop_measure)
  end

  def init(_args) do
    Process.flag(:trap_exit, true)
    port = Port.open({:spawn, "./a.out -d tmp -i 1000"}, [:binary])
    {:ok, %{port: port}}
  end

  def handle_info({_port, {:data, data}}, state) do
    Logger.info("#{inspect(data)}")
    {:noreply, state}
  end

  def handle_call(:start_measure, _from, state) do
    Port.command(state.port, "start\n")
    {:reply, :ok, state}
  end

  def handle_call(:stop_measure, _from, state) do
    Port.command(state.port, "stop\n")
    {:reply, :ok, state}
  end
end
