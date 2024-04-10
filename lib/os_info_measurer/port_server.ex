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

  def open(data_directory_path, file_name_prefix, interval_ms) do
    GenServer.call(__MODULE__, {:open, data_directory_path, file_name_prefix, interval_ms})
  end

  def close() do
    GenServer.call(__MODULE__, :close)
  end

  def init(_args) do
    Process.flag(:trap_exit, true)

    bin_path =
      Application.app_dir(:os_info_measurer)
      |> Path.join("priv/measurer")

    if File.exists?(bin_path) do
      {:ok, %{port: nil, bin_path: bin_path}}
    else
      {:stop, "#{bin_path} not found"}
    end
  end

  def handle_info({:EXIT, _port, :normal}, state) do
    {:noreply, state}
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

  def handle_call({:open, data_directory_path, file_name_prefix, interval_ms}, _from, state) do
    if is_nil(state.port) do
      port =
        Port.open(
          {:spawn,
           "#{state.bin_path} -d #{data_directory_path} -f #{file_name_prefix} -i #{interval_ms}"},
          [
            :binary,
            :exit_status
          ]
        )

      {:reply, :ok, %{state | port: port}}
    else
      Logger.error("already opened")
      {:reply, :error, state}
    end
  end

  def handle_call(:close, _from, state) do
    if is_nil(state.port) do
      Logger.error("already closed")
      {:reply, :error, state}
    else
      Port.close(state.port)
      {:reply, :ok, %{state | port: nil}}
    end
  end
end
