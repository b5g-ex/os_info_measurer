defmodule OsInfoMeasurer.PortServer do
  use GenServer

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    port = Port.open({:spawn, "./a.out"}, [:binary])
    {:ok, %{port: port}}
  end

  def handle_info({_port, {:data, data}}, state) do
    Logger.info("#{inspect(data)}")
    {:noreply, state}
  end
end
