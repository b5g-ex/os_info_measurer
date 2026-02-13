defmodule OsInfoMeasurer.PortServer do
  use GenServer

  require Logger

  def open(data_directory_path, file_name_prefix, interval_ms) do
    with :ok <- validate_directory(data_directory_path),
         :ok <- validate_interval(interval_ms) do
      GenServer.call(__MODULE__, {:open, data_directory_path, file_name_prefix, interval_ms})
    end
  end

  def close() do
    GenServer.call(__MODULE__, :close)
  end

  def start_measuring() do
    GenServer.call(__MODULE__, :start_measure)
  end

  def stop_measuring() do
    GenServer.call(__MODULE__, :stop_measure)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  defp validate_directory(path) do
    cond do
      not File.exists?(path) ->
        {:error, :directory_not_found}

      not File.dir?(path) ->
        {:error, :not_a_directory}

      true ->
        :ok
    end
  end

  defp validate_interval(interval_ms) when interval_ms > 0, do: :ok
  defp validate_interval(_), do: {:error, :invalid_interval}

  def init(_args) do
    Process.flag(:trap_exit, true)

    bin_path = Application.app_dir(:os_info_measurer) |> Path.join("priv/measurer")

    if File.exists?(bin_path) do
      {:ok, %{port: nil, bin_path: bin_path, measuring: false}}
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

  def handle_call({:open, data_directory_path, file_name_prefix, interval_ms}, _from, state) do
    cond do
      not is_nil(state.port) ->
        {:reply, {:error, :already_opened}, state}

      state.measuring ->
        {:reply, {:error, :measuring_in_progress}, state}

      true ->
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
    end
  end

  def handle_call(:close, _from, state) do
    cond do
      is_nil(state.port) ->
        {:reply, {:error, :already_closed}, state}

      state.measuring ->
        {:reply, {:error, :measuring_in_progress}, state}

      true ->
        Port.close(state.port)
        {:reply, :ok, %{state | port: nil}}
    end
  end

  def handle_call(:start_measure, _from, state) do
    cond do
      is_nil(state.port) ->
        {:reply, {:error, :not_opened}, state}

      state.measuring ->
        {:reply, {:error, :already_measuring}, state}

      true ->
        Port.command(state.port, "start\n")
        {:reply, :ok, %{state | measuring: true}}
    end
  end

  def handle_call(:stop_measure, _from, state) do
    cond do
      is_nil(state.port) ->
        {:reply, {:error, :not_opened}, state}

      not state.measuring ->
        {:reply, {:error, :not_measuring}, state}

      true ->
        Port.command(state.port, "stop\n")
        {:reply, :ok, %{state | measuring: false}}
    end
  end
end
