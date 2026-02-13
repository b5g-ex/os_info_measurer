defmodule OsInfoMeasurer do
  @moduledoc """
  OS情報計測ライブラリ。

  C++バイナリを使用してLinux OSの情報（CPU、メモリ）を定期的に計測し、
  CSVファイルへ出力します。
  """

  alias OsInfoMeasurer.PortServer

  @doc """
  OS情報の計測を開始します。

  ## パラメータ
  - `data_directory_path` - CSV出力先ディレクトリパス
  - `file_name_prefix` - CSVファイル名のプレフィックス
  - `interval_ms` - 計測間隔（ミリ秒）

  ## 戻り値
  - `:ok` - 正常に開始した
  - `{:error, reason}` - エラー発生

  ## 例
      iex> OsInfoMeasurer.start("tmp", "test", 100)
      :ok
  """
  @spec start(Path.t(), String.t(), pos_integer()) ::
          :ok | {:error, PortServer.error_reason()}
  def start(data_directory_path, file_name_prefix, interval_ms) do
    with :ok <- PortServer.open(data_directory_path, file_name_prefix, interval_ms),
         :ok <- PortServer.start_measuring() do
      :ok
    end
  end

  @doc """
  OS情報の計測を停止します。

  ## 戻り値
  - `:ok` - 正常に停止した
  - `{:error, reason}` - エラー発生

  ## 例
      iex> OsInfoMeasurer.stop()
      :ok
  """
  @spec stop() :: :ok | {:error, PortServer.error_reason()}
  def stop() do
    with :ok <- PortServer.stop_measuring(),
         :ok <- PortServer.close() do
      :ok
    end
  end

  @doc """
  現在の状態を取得します。

  ## 戻り値
  - `:idle` - Port接続が開かれていない
  - `:opened` - Port接続は開かれているが計測していない
  - `:measuring` - 計測中
  """
  @spec status() :: :idle | :opened | :measuring
  def status() do
    PortServer.status()
  end

  @doc """
  現在計測中かどうかを返します。

  ## 戻り値
  - `true` - 計測中
  - `false` - 計測していない
  """
  @spec measuring?() :: boolean()
  def measuring?() do
    PortServer.measuring?()
  end
end
