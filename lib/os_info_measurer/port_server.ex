defmodule OsInfoMeasurer.PortServer do
  @moduledoc """
  OS情報計測用のC++バイナリとPort通信を管理するGenServer。

  C++バイナリ（priv/measurer）を起動し、Linux OSの情報（CPU、メモリ）を
  定期的に計測してCSVファイルへ出力する機能を提供します。
  """

  use GenServer

  require Logger

  @measurer_binary_path "priv/measurer"

  @typedoc "開放・計測操作のエラー理由"
  @type error_reason ::
          :directory_not_found
          | :not_a_directory
          | :invalid_interval
          | :already_opened
          | :already_closed
          | :measuring_in_progress
          | :not_opened
          | :already_measuring
          | :not_measuring

  @doc """
  C++バイナリとのPort接続を開きます。

  ## パラメータ
  - `data_directory_path` - CSV出力先ディレクトリパス（存在する必要あり）
  - `file_name_prefix` - CSVファイル名のプレフィックス
  - `interval_ms` - 計測間隔（ミリ秒、正の整数）

  ## 戻り値
  - `:ok` - 正常に開いた
  - `{:error, reason}` - エラー発生

  ## エラー理由
  - `:directory_not_found` - 指定ディレクトリが存在しない
  - `:not_a_directory` - 指定パスがディレクトリではない
  - `:invalid_interval` - 計測間隔が0以下
  - `:already_opened` - すでに開いている
  - `:measuring_in_progress` - 計測中のため開けない
  """
  @spec open(Path.t(), String.t(), pos_integer()) :: :ok | {:error, error_reason()}
  def open(data_directory_path, file_name_prefix, interval_ms) do
    with :ok <- validate_directory(data_directory_path),
         :ok <- validate_interval(interval_ms) do
      GenServer.call(__MODULE__, {:open, data_directory_path, file_name_prefix, interval_ms})
    end
  end

  @doc """
  Port接続を閉じます。

  ## 戻り値
  - `:ok` - 正常に閉じた
  - `{:error, reason}` - エラー発生

  ## エラー理由
  - `:already_closed` - すでに閉じている
  - `:measuring_in_progress` - 計測中のため閉じられない
  """
  @spec close() :: :ok | {:error, error_reason()}
  def close() do
    GenServer.call(__MODULE__, :close)
  end

  @doc """
  OS情報の計測を開始します。

  Port接続を開いた後に実行する必要があります。

  ## 戻り値
  - `:ok` - 正常に開始した
  - `{:error, reason}` - エラー発生

  ## エラー理由
  - `:not_opened` - Port接続が開かれていない
  - `:already_measuring` - すでに計測中
  """
  @spec start_measuring() :: :ok | {:error, error_reason()}
  def start_measuring() do
    GenServer.call(__MODULE__, :start_measure)
  end

  @doc """
  OS情報の計測を停止します。

  ## 戻り値
  - `:ok` - 正常に停止した
  - `{:error, reason}` - エラー発生

  ## エラー理由
  - `:not_opened` - Port接続が開かれていない
  - `:not_measuring` - 計測していない
  """
  @spec stop_measuring() :: :ok | {:error, error_reason()}
  def stop_measuring() do
    GenServer.call(__MODULE__, :stop_measure)
  end

  @doc false
  @spec start_link(term()) :: GenServer.on_start()
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

    app_dir_path = Application.app_dir(:os_info_measurer)
    bin_path = Path.join(app_dir_path, @measurer_binary_path)

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
