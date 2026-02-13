# OsInfoMeasurer

Linux OS の情報（CPU使用率、メモリ使用量）を定期的に計測してCSVファイルに記録するツール。

`/proc/stat` 一行目と `free` コマンドの結果をC++バイナリで計測し、Elixirのポート経由で利用できます。

- **Elixir**: `Port` 経由で使用
- **Python**: `subprocess.Popen` 経由で使用
- **C++**: `popen` 経由で使用

## インストール

### 前提条件
- Linux環境
- Elixir 1.14以上
- C++20対応のコンパイラ（g++ 11以上など）

### セットアップ

```bash
# プロジェクトに追加
mix deps.get

# C++バイナリをビルド
mix compile
```

## 基本的な使い方

### シンプルな例

```elixir
# 計測を開始（tmp ディレクトリに csv_test*.csv として1秒間隔で記録）
OsInfoMeasurer.start("tmp", "csv_test", 1000)

# 計測を停止
OsInfoMeasurer.stop()
```

### 状態確認

```elixir
# 現在の状態を取得
OsInfoMeasurer.status()  # => :idle | :opened | :measuring
OsInfoMeasurer.measuring?()  # => true | false
```

### エラーハンドリング

```elixir
case OsInfoMeasurer.start("tmp", "test", 500) do
  :ok ->
    IO.puts("計測開始")

  {:error, :directory_not_found} ->
    IO.puts("ディレクトリが見つかりません")

  {:error, :invalid_interval} ->
    IO.puts("計測間隔は0より大きい値を指定してください")

  {:error, reason} ->
    IO.puts("エラー: #{inspect(reason)}")
end
```

### Python からの使用方法

`subprocess.Popen` 経由で measurer バイナリを起動し、stdin 経由で `start` と `stop` コマンドを送信します。

実装例は [src/test_caller.py](src/test_caller.py) を参照してください。

### C++ からの使用方法

`popen` 経由で measurer バイナリを起動し、stdin 経由で `start` と `stop` コマンドを送信します。

実装例は [src/test_caller.cpp](src/test_caller.cpp) を参照してください。

## 出力ファイル

計測を開始すると、指定されたディレクトリに CSV ファイルが生成されます。

### ファイル名規則

```
{prefix}_free.csv     # メモリ情報
{prefix}_proc_stat.csv  # CPU情報
```

### CSVフォーマット（例）

**proc_stat.csv**
```
time[ms],user,nice,system,idle,iowait,irq,softirq,steal,guest,guest_nice
1707840330000,1000,50,500,50000,100,10,5,0,0,0
```

**free.csv**
```
time[ms],total[KiB],used[KiB],free[KiB],shared[KiB],buff/cache[KiB],available[KiB]
1707840330000,8000000,4000000,2000000,500000,1000000,2000000
```

#### フォーマット詳細

- **time[ms]**: UNIXタイムスタンプ（ミリ秒）。`std::chrono::system_clock::now().time_since_epoch()` から計算
- **proc_stat**: `/proc/stat` の CPU 行から取得（`man 5 proc` 参照）
- **free**: `free` コマンド出力から取得。標準 Linux の `free` と BusyBox（Nerves で使用） の両方に対応

#### Nerves での利用

Nerves 環境でも利用可能です。以下は BusyBox の `free` 出力フォーマットにも対応しています：

- `/proc/stat` 読み込み - Nerves ルートファイルシステムで利用可能
- `free` コマンド実行 - BusyBox 版 `free` をサポート

## トラブルシューティング

### C++バイナリが見つからない

```
** (stop) {:binary_not_found, "/path/to/priv/measurer"}
```

**解決方法:**
```bash
mix compile
```

### "already_opened" エラー

すでに計測が開始されています。`OsInfoMeasurer.stop()` で停止してから `start()` を呼び出してください。

```elixir
OsInfoMeasurer.stop()
OsInfoMeasurer.start("tmp", "test", 1000)
```

### CSVファイルが生成されない

1. 出力ディレクトリが存在し、書き込み権限があるか確認
2. ディスクの空き容量を確認
3. `OsInfoMeasurer.measuring?()` で計測中か確認

## リファレンス

### メイン API

- `OsInfoMeasurer.start/3` - 計測開始
- `OsInfoMeasurer.stop/0` - 計測停止
- `OsInfoMeasurer.status/0` - ステータス確認
- `OsInfoMeasurer.measuring?/0` - 計測中か確認

詳細は `lib/os_info_measurer.ex` の `@doc` を参照してください。

## 技術情報

### CPU使用率の計算

- [StackOverflow: CPU 使用率計算](https://stackoverflow.com/questions/23367857/accurate-calculation-of-cpu-usage-given-in-percentage-in-linux#answer-23376195)

### iowait について

- [Twitter: iowait に関する考察](https://twitter.com/search?q=from%3A%40n_soda%20iowait&src=recent_search_click&f=live)
