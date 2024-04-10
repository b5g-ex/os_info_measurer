defmodule OsInfoMeasurer do
  @moduledoc """
  Documentation for `OsInfoMeasurer`.
  """

  def start(data_directory_path, file_name_prefix, interval_ms) do
    OsInfoMeasurer.PortServer.open(data_directory_path, file_name_prefix, interval_ms)
    OsInfoMeasurer.PortServer.start_measure()
  end

  def stop() do
    OsInfoMeasurer.PortServer.stop_measure()
    OsInfoMeasurer.PortServer.close()
  end
end
