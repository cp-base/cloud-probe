# 実装構成と制作手順の記録

## 参照・抽出

1. `Chappy.md`から関連資料を辿り、現在のゲームを `index.html` の CLOUD / PROBE 05 と特定。
2. `STATUS`と`DECISIONS`で「実装済み」「仮採用」「未決定候補」を分離。今回は自由移動・信号調査・ミニマップ・操作UIを優先した。
3. HTMLの関数を確認。`makeWorld`, `move`, `updateDiscovery`, `useEvent`, `renderScene`, `renderMap`, `purchase`, `saveGame` の責務と数値を抽出。
4. シード値・Mulberry32をGodot側に移植。初期信号ID1（x=-12.161510676..., y=139.322810063...）の一致を検査した。

## ワークフロー（再利用可能な作業の観測）

1. ツール倉庫から Linux Godot 4.7.2 stable のZIPを取得し展開。`--headless --version`で実行確認。
2. `project.godot`を作成。`Main.tscn`にWorldモデル、`SceneView.tscn`・`MiniMap.tscn`を別シーンとして用意。
3. `world.gd`へ状態・ワールド生成・イベント・強化・JSON保存を集約。UI・描画は`main.gd`, `scene_view.gd`, `mini_map.gd`へ分離。
4. 疑似一人称はGodot 2D `CanvasItem` の描画API（`draw_line`, `draw_arc`, `draw_colored_polygon`, `draw_circle`, `draw_string`）で再実装。
5. 操作はGodot標準 `Button` に`button_down`, `button_up`, `toggled`, `pressed` を接続。進行をControl上のLabel・ProgressBarへ反映。リセット確認は `ConfirmationDialog`を利用。
6. Godot `--headless --editor --import --quit` でインポート・構文チェック。初回の描画メソッド名の衝突・未対応InputEvent型・文字列フォーマット順序の問題を修正。
7. `test_world.gd`（25ケース）と`test_ui.gd`（9ケース）をGodotで実行し成功。Xvfb+Mesa環境で実際の画面を撮影。

## 実装上の留保

- worldの計算はGDScript、画面はGodot 2D。3Dに変更していない。
- HTMLと同じバランス値（速度25、燃料消費0.42/移動単位、旋回1.8rad/s、探知34、調査15、周囲地図250、世界半径10000）は**比較用の暫定値**。
- 制作時に見つかったコード上の差分を報告するが、仕様の新規確定はしない。HTMLの既知の燃料回復上限100は移植版でも一致させた。
- シーンのUI構成は、World/SceneView/MiniMapを分離し、UIは`Main`が標準Controlで組み立てる。今後UI全体をGodotエディタで構成する方式とは、工数比較が別途必要。
- テストは状態注入によって調査・遠方到達ケースを短縮している。全域を手動操作で走破した結果ではない。
- Godot本体のバイナリや機能候補の採否をGitHubへ追加しない。
