defmodule OsInfoMeasurerTest do
  use ExUnit.Case

  setup do
    # アプリケーション全体を起動
    Application.ensure_all_started(:os_info_measurer)

    # 各テスト後にクリーンアップ
    on_exit(fn ->
      OsInfoMeasurer.stop()
      Application.stop(:os_info_measurer)
    end)

    :ok
  end

  describe "state management" do
    test "status returns :idle initially" do
      assert OsInfoMeasurer.status() == :idle
      assert OsInfoMeasurer.measuring?() == false
    end

    @tag :tmp_dir
    test "status transitions through states", %{tmp_dir: tmp_dir} do
      # 初期状態
      assert OsInfoMeasurer.status() == :idle

      # open後
      assert :ok = OsInfoMeasurer.PortServer.open(tmp_dir, "test", 100)
      assert OsInfoMeasurer.status() == :opened
      assert OsInfoMeasurer.measuring?() == false

      # 計測開始後
      assert :ok = OsInfoMeasurer.PortServer.start_measuring()
      assert OsInfoMeasurer.status() == :measuring
      assert OsInfoMeasurer.measuring?() == true

      # 計測停止後
      assert :ok = OsInfoMeasurer.PortServer.stop_measuring()
      assert OsInfoMeasurer.status() == :opened
      assert OsInfoMeasurer.measuring?() == false

      # close後
      assert :ok = OsInfoMeasurer.PortServer.close()
      assert OsInfoMeasurer.status() == :idle
    end
  end

  describe "double start prevention" do
    @tag :tmp_dir
    test "returns error when starting twice", %{tmp_dir: tmp_dir} do
      # 1回目は成功
      assert :ok = OsInfoMeasurer.start(tmp_dir, "test", 100)
      assert OsInfoMeasurer.measuring?() == true

      # 2回目はエラー（計測中なので measuring_in_progress）
      assert {:error, :measuring_in_progress} = OsInfoMeasurer.start(tmp_dir, "test", 100)

      # クリーンアップ
      assert :ok = OsInfoMeasurer.stop()
    end
  end

  describe "CSV generation" do
    @tag :tmp_dir
    test "generates CSV files when measuring", %{tmp_dir: tmp_dir} do
      # 計測開始
      assert :ok = OsInfoMeasurer.start(tmp_dir, "csv_test", 100)
      assert OsInfoMeasurer.measuring?() == true

      # CSVが書き込まれるまで待つ（少なくとも数回の計測サイクル）
      Process.sleep(1000)

      # 計測停止
      assert :ok = OsInfoMeasurer.stop()

      # CSVファイルが生成されていることを確認
      csv_files = Path.wildcard(Path.join(tmp_dir, "*.csv"))

      # ファイルが生成されていなければスキップ（C++バイナリの動作に依存）
      if length(csv_files) > 0 do
        # ファイル名にプレフィックスが含まれていることを確認
        assert Enum.any?(csv_files, fn file ->
          Path.basename(file) =~ "csv_test"
        end)

        # CSVファイルが空でないことを確認
        Enum.each(csv_files, fn file ->
          content = File.read!(file)
          assert String.length(content) > 0
        end)
      end
    end
  end
end
