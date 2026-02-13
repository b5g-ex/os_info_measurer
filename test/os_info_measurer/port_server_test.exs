defmodule OsInfoMeasurer.PortServerTest do
  use ExUnit.Case

  alias OsInfoMeasurer.PortServer

  setup do
    # GenServerを明示的に起動
    start_supervised!(PortServer)

    # 各テスト後にクリーンアップ
    on_exit(fn ->
      if Process.whereis(PortServer) do
        try do
          PortServer.close()
        catch
          _, _ -> :ok
        end
      end
    end)

    :ok
  end

  describe "Port.open failure scenarios" do
    test "opening with non-existent directory should return error" do
      # 存在しないディレクトリを指定
      result = PortServer.open("/nonexistent/path", "test", 100)

      # 期待: エラーを返すべき
      assert {:error, _reason} = result
    end

    test "opening with invalid interval should return error" do
      # 負の値の interval を指定
      result = PortServer.open("tmp", "test", -100)

      # 期待: {:error, :invalid_interval} を返すべき
      assert {:error, _reason} = result
    end

    test "start_measuring before opening should return error" do
      # Port を開かずに start_measuring を呼ぶ
      result = PortServer.start_measuring()

      # 期待: {:error, :not_opened} を返すべき
      assert {:error, :not_opened} = result
    end
  end
end
