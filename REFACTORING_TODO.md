# リファクタリング TODO

## 現状の課題
1. **API設計**: エラーハンドリング不足、状態管理が不明確
2. **ドキュメント**: 使用例がない、関数の説明が不足
3. **テスト**: デフォルトテストが壊れている、実際の計測テストがない
4. **柔軟性**: デフォルト値がない、引数が多い

## Phase 1: 安定性向上（優先度：高）

- [x] **1. PortServerにエラーハンドリング追加**
  - 2重起動防止
  - Port未初期化状態でのコマンド送信防止
  - バイナリファイル存在チェック強化

- [x] **2. start/stopの戻り値を`:ok | {:error, reason}`に変更**
  - エラー理由: `:already_started`, `:not_started`, `:binary_not_found`

- [x] **3. 状態管理機能追加**
  - `OsInfoMeasurer.status/0` → `:idle | :measuring | {:error, reason}`
  - `OsInfoMeasurer.measuring?/0` → `true | false`

- [x] **4. 壊れたテストを削除**
  - `test/os_info_measurer_test.exs`の`hello()`テストを削除

- [x] **5. 実際の計測テストを追加**
  - CSV生成テスト
  - 2重起動防止テスト
  - 異常系テスト

## Phase 2: ドキュメント整備（優先度：中）

- [ ] **6. @moduledocと@docを充実**
  - モジュールと各公開関数に説明追加
  - 使用例をdoctest形式で記載

- [ ] **7. README.mdに使用例を追加**
  - インストール方法、基本的な使い方
  - 出力ファイルの説明
  - トラブルシューティング

## Phase 3: API改善（優先度：中）

- [ ] **8. キーワード引数版API追加**
```elixir
# 既存API（維持）
OsInfoMeasurer.start(data_directory_path, file_name_prefix, interval_ms)

# 新API
OsInfoMeasurer.start(output_dir: "tmp", prefix: "test", interval: 500)
OsInfoMeasurer.start() # 全部デフォルト
```

- [ ] **9. デフォルト値設定の実装**
  - `output_dir`: `"tmp"`, `prefix`: `""`, `interval`: `100` (ms)

- [ ] **10. measure/2ブロック構文追加**
```elixir
OsInfoMeasurer.measure(interval: 500) do
  run_benchmark()
end
```

## Phase 4: 拡張性向上（優先度：低）

- [ ] **11. 設定ファイル(config.exs)対応**
```elixir
config :os_info_measurer,
  default_output_dir: "measurements",
  default_interval: 500
```

- [ ] **12. test_run.exsをexampleに整理**
  - `examples/basic_usage.exs` に移動
  - コメントを充実

## 実装順序
1. Phase 1 (1→2→3→4→5) - 安定性を確保
2. Phase 2 (6→7) - ドキュメントで使いやすさ向上
3. Phase 3 (8→9→10) - APIを改善
4. Phase 4 (11→12) - 拡張機能

## 進捗: 5/12
開始日: 2026年2月12日
Phase 1完了日: 2026年2月13日

## 注意事項
- 既存のAPI（`start/3`）は維持し併存させる
- ExUnitでの単体テスト + CSV生成を伴う統合テスト
- @docにはdoctestを含める
