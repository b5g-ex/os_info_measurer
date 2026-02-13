defmodule OsInfoMeasurer.PortServerTest do
  use ExUnit.Case

  alias OsInfoMeasurer.PortServer

  setup do
    # GenServerを明示的に起動
    start_supervised!(PortServer)

    # 各テスト後にクリーンアップ
    on_exit(fn ->
      if Process.whereis(PortServer) do
        PortServer.close()
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

    @tag :tmp_dir
    test "opening with invalid interval should return error", %{tmp_dir: tmp_dir} do
      # 負の値の interval を指定
      result = PortServer.open(tmp_dir, "test", -100)

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

  describe "exit_status handling" do
    @tag :tmp_dir
    @tag :capture_log
    test "handles abnormal termination when binary is killed", %{tmp_dir: tmp_dir} do
      # Portを開く
      assert :ok = PortServer.open(tmp_dir, "abnormal_exit_test", 100)

      # 開いた状態を確認してPortのOS pidを取得
      state_before = :sys.get_state(PortServer)
      assert not is_nil(state_before.port)
      assert state_before.measuring == false

      # PortのOS pidを取得
      {:os_pid, os_pid} = Port.info(state_before.port, :os_pid)

      # 特定のmeasurerプロセスだけをkillする
      {_output, 0} = System.cmd("kill", ["-9", "#{os_pid}"])

      # exit_statusメッセージが処理されるまで待つ
      Process.sleep(100)

      # 状態がクリーンアップされたことを確認
      state_after = :sys.get_state(PortServer)
      assert is_nil(state_after.port)
      assert state_after.measuring == false

      # 再度openできることを確認
      assert :ok = PortServer.open(tmp_dir, "after_kill_test", 100)
      assert :ok = PortServer.close()
    end
  end
end
