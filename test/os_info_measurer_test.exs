defmodule OsInfoMeasurerTest do
  use ExUnit.Case
  doctest OsInfoMeasurer

  test "module has start and stop functions" do
    assert function_exported?(OsInfoMeasurer, :start, 3)
    assert function_exported?(OsInfoMeasurer, :stop, 0)
  end
end
