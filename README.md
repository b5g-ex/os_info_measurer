# OsInfoMeasurer

`/proc/stat` 一行目と `free` コマンドの結果を計測（ログ）するプログラムです。

- Elixir からは `Port` 経由で使用します。
- Python からは `subprocess.Popen` 経由で使用します。
- C++ からは `popen` 経由で使用します。

## `/proc/stat` からの CPU 使用率計算

- https://stackoverflow.com/questions/23367857/accurate-calculation-of-cpu-usage-given-in-percentage-in-linux#answer-23376195

### iowait について

- https://twitter.com/search?q=from%3A%40n_soda%20iowait&src=recent_search_click&f=live
