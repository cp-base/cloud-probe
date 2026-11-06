# CLOUD / PROBE — UI・操作画面独立研究

2026-11-07 / ブランチ research/ui / 対象 Foundation v0.3

**状態：研究試作。採用・mainへのマージは未決定。** 既存HTML index.html、旧godot/、共有STATUS.md・DECISIONS.md・HISTORY.mdは変更しない。

## 対象と変更方針

Foundationの `ui/main.gd` は、航行HUD・UIボタン・モーダル画面をすべて動的に生成している。研究では、ゲーム進行ルールを変えずに画面の「置き方」だけをシーンエディタで変更可能なファイルへ切り出した。

- `Main.tscn` のスクリプトを研究アダプタに変更（元のUIスクリプト自体は無変更）。
- `ui/research_ui_main.gd` が `ui/main.gd` を継承して、`_build_ui` / `_open_modal` をoverride。Session、描画、保存、施設処理、航行入力の計算は元の実装を継承。
- `ui/layouts/hud.tscn` に上部の状態・アクション、ミニマップ枠、下部のメーター・移動操作を移した。
- `ui/layouts/modal_shell.tscn` を施設、地図、信号、設定の共通外殻に使用。**施設の5タブ内部は既存スクリプトの生成を維持**（研究範囲）。
- `ui/theme/cloud_probe_theme.tres` でパネル・ボタンの色と余白を共有化。

## 使用部品・資料

Godot標準：CanvasLayer、Control、PanelContainer、VBoxContainer、HBoxContainer、HFlowContainer、TabContainer、Theme、StyleBoxFlat、PackedScene、signal、SubViewport。既存：`ui/main.gd`、`ui/map_view.gd`、`tests/test_ui.gd`、`core/session.gd`。

確認した元資料：`Chappy.md`、`godot-foundation/README.md`、`docs/godot-foundation/README.md`、同ディレクトリの制作手順・検証記録・設計図。関連するGodot公式の [Theme](https://docs.godotengine.org/en/stable/tutorials/ui/gui_skinning.html) / [HFlowContainer](https://docs.godotengine.org/en/stable/classes/class_hflowcontainer.html) / [Theme editor](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_theme_editor.html)。

## 変更ファイル

| ファイル | 役割 |
|---|---|
| `godot-foundation/Main.tscn` | 研究スクリプトへ入口を切替（1行相当） |
| `godot-foundation/ui/research_ui_main.gd` | 既存コールバック接続・UIシーン生成 |
| `godot-foundation/ui/layouts/hud.tscn` | 編集可能なHUDの画面階層 |
| `godot-foundation/ui/layouts/modal_shell.tscn` | 再利用できるモーダル外殻 |
| `godot-foundation/ui/theme/cloud_probe_theme.tres` | 共通スタイル |
| `godot-foundation/tests/ui_layout_smoke.gd` | UI部品・実サイズ領域の23項目 |
| `godot-foundation/tests/ui_foundation_integration.gd` | Foundation実体とのUI統合検査 |
| `godot-foundation/tests/ui_capture.gd` | UIだけの表示プレビュー撮影。表示値は例示 |
| `godot-foundation/research/ui/*` | 検証・証拠・本報告 |
| `.github/workflows/ui-research.yml` | research/ui 専用の回帰検査。mainを変更しない |

ゲームの `core/`・`data/`・`visuals/`、および既存 `ui/main.gd` は変更していない。

## 実際のテスト

使用したGodot：ライブラリのLinux版 `Godot_v4.7.2-stable_linux.x86_64.zip`。実行出力は `4.7.2.stable.official.ed1daf0bf`。作業は独立した一時ワークスペースで実施し、ローカルの他担当worktreeは使わなかった。

1. `Godot --headless --path godot-foundation --script res://tests/ui_layout_smoke.gd`：**23項目成功／失敗0**。800×600、1180×760、1920×1080の実SubViewportで、HUD横幅・上下重なり・ミニマップと操作領域の分離・ボタン高を確認。
2. 継承アダプタのローカル代替基底クラス試験：**10項目成功／失敗0**。ボタン発火、長押しと離す、モーダル表示と閉じる、Theme・ミニマップSession接続の構造を確認。ただし実Foundationではなく、ローカル専用のスタブ。スタブはブランチへ登録していない。
3. Xvfb＋Godot OpenGL描画：`hud-800.png`、`hud-1180.png`、`modal-1180.png` の3枚を出力できた。表示値はテスト用サンプルで、ゲーム実プレイのスクリーンショットではない。ローカル添付と `tests/ui_capture.gd` に再生成手順を残した。
4. Foundation基準の既存記録：v0.3処理42項目＋UI6項目成功。ただし**研究UI適用後にローカル本体全体を起動した結果ではない**。

Godot本体のリポジトリはGitHub連携からソースを確認できたが、一時コンテナの通常ネットワークからGitHubをcloneできなかった。このためローカルではUI単体・スタブまで実行。実際のFoundation一式で確認するため、`ui_foundation_integration.gd` と、ブランチ限定のGitHub Actions回帰テストを用意した（CIの成否は結果確定後に追記）。

## 比較・評価

| 観点 | Foundationの動的UI | 今回のシーン化 |
|---|---|---|
| 画面配置 | スクリプト中のControl生成・数値変更が必要 | .tscnのノード階層とInspectorから変更可能 |
| スタイル | 個別overrideとStyleBox | Theme Resourceから一括変更可能 |
| 複数解像度 | 固定幅配置が多い | 上下アンカーとHFlowContainer。3サイズの部品試験に成功 |
| 画面の再利用 | モーダルを毎回コード生成 | 外殻は共通シーン。施設タブ内部は現行のまま |
| ChatGPTによる修正 | UI1関数に集中 | Scene / Theme / 接続スクリプトを分業可能。ただしNodePath整合性検査が必要 |
| 進行ルール | 既存 | 変更なし（同じ既存コールバックへ接続） |

**導入難度：中（暫定）**。採用する場合は `Main.tscn`、アダプタ、2シーン、Theme、関連テストをまとめて移す。既存UIへ戻すには `Main.tscn` のScript参照を `res://ui/main.gd` に戻せばよい。採否は比較後に決定する。

## 問題・未確認・候補

- 研究UIを使った実FoundationでのF5起動と、出発→航行→施設→改修→保存→再開の通し操作。キーボード＋マウス長押しの実操作。
- 施設内には幅480の選択欄などがあり、800未満や狭い縦長画面では別途調整が必要。
- UIボタンは既存のキーボード移動を阻害しないためfocus_mode NONE。ゲームパッド・TabによるUI操作は未検証。
- 高DPI、長い翻訳文、フォント代替、マウスキャンセル、エディタでの実作業時間は未計測。
- 将来候補として施設ページ内部のScene化と更新処理の分離があるが、今回の本番仕様には採用していない。

