# UI v2 証拠と再現方法

## GitHub内の自動記録

- [Actions run 42304817753（success）](https://github.com/cp-base/cloud-probe/actions/runs/42304817753)
- `ui-v2-source` artifact：独立ソースZIP（`git archive` による追跡対象のみ）。他ブランチやPCのworktreeを使わない。
- `ui-v2-screenshots` artifact：CIで生成したHUD 640/800/1180/1920と640モーダルの5枚。**CIには日本語フォントがなく、文字化けする。**
- 同じrunのログ：`UI_RESEARCH_RESULT 23/0`、`UI_COMPACT_RESULT 51/0`、`UI_MOUSE_RESULT 10/0`、`UI_INTEGRATION_RESULT 12/0`、`UI_RESULT 6/0`、`RESULT 42/0`、画面キャプチャ5/0。

## 独立Linux一時ワークスペースでの実行

- ライブラリGodot `Godot_v4.7.2-stable_linux.x86_64.zip` から展開し、`--version` で `4.7.2.stable.official.ed1daf0bf` を確認。
- `ui-v2-source` artifact内のZIPを別ディレクトリへ展開（保存と検査はゲーム実プロジェクトと分離）。
- `godot --headless --editor --path godot-foundation --import --quit`
- `godot --headless --path godot-foundation --script res://tests/ui_layout_smoke.gd`
- `godot --headless --path godot-foundation --script res://tests/ui_compact_smoke.gd`
- `godot --headless --path godot-foundation --script res://tests/ui_mouse_smoke.gd`
- `godot --headless --path godot-foundation --script res://tests/ui_foundation_integration.gd`
- `godot --headless --path godot-foundation --script res://tests/test_ui.gd`
- `godot --headless --path godot-foundation --script res://tests/test_session.gd`
- 日本語フォント（Noto Sans CJK JP）と仮想ディスプレイ（Xvfb）が利用可能な環境で `xvfb-run -a godot --rendering-method gl_compatibility --path godot-foundation --script res://tests/ui_v2_capture.gd`
- 同様に `--script res://tests/ui_live_capture.gd` で実Foundation起動から `live-preparation.png` と `live-travel.png` を取得する。

## 画像の区別

- サンプルUIのプレビュー：`hud-640.png`、`hud-800.png`、`hud-1180.png`、`hud-1920.png`、`modal-640.png`。
- **実Foundationシーンの描画**：`live-preparation.png`、`live-travel.png`（`_depart("base")` をスクリプトから実行、保存OFF）。
- 本チャットではこの7画像とログをローカル証拠ZIPでも納品。これは **GitHubで自動pushされたPNGではない**。GitHubにあるのはソースと再現スクリプト・CI記録。

未検証：手動でF5から長時間プレイ、操作の身体感覚・連続プレイ時の誤操作、実Windowsでの見え方、パッド、高DPI。
