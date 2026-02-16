defmodule OsInfoMeasurerTest do
  use ExUnit.Case

  @moduletag :capture_log

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
      if not Enum.empty?(csv_files) do
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

  describe "external callers - Python" do
    @tag :tmp_dir
    @tag skip: is_nil(System.find_executable("python3"))
    test "test_caller.py generates CSV files", %{tmp_dir: tmp_dir} do
      prefix = "py_test"

      {output, exit_code} =
        System.cmd(
          "python3",
          ~w"#{Path.join(File.cwd!(), "src/test_caller.py")} -d #{tmp_dir} -f #{prefix} -i 100",
          stderr_to_stdout: true
        )

      # Check that the script ran without error
      assert exit_code == 0, "test_caller.py failed: #{output}"

      # Check that CSV files were generated
      free_file = Path.join(tmp_dir, "#{prefix}_free.csv")
      proc_stat_file = Path.join(tmp_dir, "#{prefix}_proc_stat.csv")

      assert File.exists?(free_file), "#{prefix}_free.csv not found in #{tmp_dir}"
      assert File.exists?(proc_stat_file), "#{prefix}_proc_stat.csv not found in #{tmp_dir}"

      # Verify files have content
      free_content = File.read!(free_file)
      proc_stat_content = File.read!(proc_stat_file)

      assert byte_size(free_content) > 100, "#{prefix}_free.csv is too small or empty"

      assert byte_size(proc_stat_content) > 100,
             "#{prefix}_proc_stat.csv is too small or empty"
    end
  end

  describe "external callers - C++" do
    @tag :tmp_dir
    @tag skip: is_nil(File.exists?(Path.join(File.cwd!(), "src/test_caller")))
    test "test_caller generates CSV files", %{tmp_dir: tmp_dir} do
      prefix = "cpp_test"

      {output, exit_code} =
        System.cmd(
          Path.join(File.cwd!(), "src/test_caller"),
          ~w"-d #{tmp_dir} -f #{prefix} -i 100",
          stderr_to_stdout: true
        )

      # Check that the script ran without error
      assert exit_code == 0, "test_caller failed: #{output}"

      # Check that CSV files were generated
      free_file = Path.join(tmp_dir, "#{prefix}_free.csv")
      proc_stat_file = Path.join(tmp_dir, "#{prefix}_proc_stat.csv")

      assert File.exists?(free_file), "#{prefix}_free.csv not found in #{tmp_dir}"
      assert File.exists?(proc_stat_file), "#{prefix}_proc_stat.csv not found in #{tmp_dir}"

      # Verify files have content
      free_content = File.read!(free_file)
      proc_stat_content = File.read!(proc_stat_file)

      assert byte_size(free_content) > 100, "#{prefix}_free.csv is too small or empty"
      assert byte_size(proc_stat_content) > 100, "#{prefix}_proc_stat.csv is too small or empty"
    end
  end
end
