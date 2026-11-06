# CLOUD / PROBE 05 — Godot移植比較実験

**これは比較検証用の別プロジェクトであり、製品仕様の確定やHTML版の置き換えではありません。**

参照元：[`cp-base/cloud-probe/main/index.html`](../index.html) / [`Chappy.md`](../Chappy.md)。確認時点のHTML blob SHA：`1d0b2c88532f4fa751c2002e88b9527e23f0501e`。

## 起動

Godot **4.7.2 stable** でこのディレクトリの `project.godot` を開き、`F6` ではなく **F5（Main.tscn）** で実行。Godotランタイムはリポジトリには含みません。テストしたのはライブラリ「ツール倉庫」提供の **Linux x86_64版**。WindowsやiOSの実行・エクスポートは未検証です。

操作：**↑ / W（前進）、↓ / S（後退）、← → / A D（旋回）**、画面の2段6ボタンでも同じ動作。**自動前進**はON/OFF切り替え。**調べる**は対象まで15未満の距離で有効。補給・調査・起点購入を試せます。Godot版はデータを `user://cloud_probe_godot_compare.json` に保存し、HTMLの `localStorage` とは分離しています。

## 構成

| 場所 | 役割 |
|---|---|
| `scenes/Main.tscn`, `scripts/main.gd` | Controlベースの操作UI、HUD、強化ターミナルと接続 |
| `scripts/world.gd` | 座標、ワールド生成、信号、燃料、敵、強化、保存・帰還 |
| `scenes/SceneView.tscn`, `scripts/scene_view.gd` | Godot CanvasItemによる疑似一人称投影・図形 |
| `scenes/MiniMap.tscn`, `scripts/mini_map.gd` | プレイヤー中心・北が上の周辺地図 |
| `tests/test_world.gd` | ロジック・HTMLの初期シード・保存など25項目 |
| `tests/test_ui.gd` | 標準Buttonと状態連動など9項目 |
| `tests/capture.gd` | Xvfbで実画面の証拠画像を取得する補助 |
| `evidence/` | 実行結果JSONと撮影画像。テスト中の位置変更は証拠画像専用 |
| `docs/` | 制作手順、比較、検証範囲と限界 |

## 検証コマンド（このフォルダで実行）

```bash
GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64
"$GODOT" --headless --editor --path . --import --quit
"$GODOT" --headless --path . --script res://tests/test_world.gd
"$GODOT" --headless --path . --script res://tests/test_ui.gd
# XvfbとMesa/OpenGLが利用できるLinux環境の場合
xvfb-run -a "$GODOT" --audio-driver Dummy --rendering-driver opengl3 \
  --path . --script res://tests/capture.gd
```

**結果：ロジック25/25、UI9/9、画面描画1280×900成功。** これは現環境の結果で、iPhone実機・端末操作感・HTML画面とのピクセル一致を確認したものではありません。

報告：[比較](docs/COMPARISON.md) / [実装と制作手順](docs/IMPLEMENTATION_NOTES.md) / [検証記録](docs/VERIFICATION.md)。将来仕様の候補は元の [`docs/CANDIDATES.md`](../docs/CANDIDATES.md) に従い未決定のままです。
