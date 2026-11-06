# 実行・検証報告（2026-11-06）

## 実行環境

- Godot：**4.7.2.stable.official.ed1daf0bf**、ツール倉庫 `Godot_v4.7.2-stable_linux.x86_64.zip` から取得（78MB級ZIP）。Linux x86_64。
- モデル実行：Godot `--headless`。
- UI実画面：Xvfb 1280×900、Mesa llvmpipe OpenGL 4.5 Compatibility、ダミーオーディオ。
- 元の `index.html` はブラウザ内で起動していない。元のGitHub HTMLソースはコードを読み込んで比較し、元資料に記載された以前のブラウザ試験結果を参照した。今回の環境で **HTML・Godot両者の同時画面比較は未実施**。

## コマンド結果

| 手順 | 結果 |
|---|---|
| `godot --headless --version` | 4.7.2 stable と確認 |
| `godot --headless --editor --import --quit` | 初回構文エラー修正後、エラーなし |
| `godot --headless --path . --quit-after 25` | 起動継続・実行時エラーなし |
| `godot --headless --path . --script res://tests/test_world.gd` | **25/25通過**、`evidence/TEST_RESULTS.json` |
| `godot --headless --path . --script res://tests/test_ui.gd` | **9/9通過**、`evidence/UI_TEST_RESULTS.json` |
| Xvfb+`tests/capture.gd` | 1280×900の**初期・接近・調査後**の3枚をPNG保存、エラーコード0 |

### 主な合格内容

- HTMLのシード20261106からの最初の信号位置の一致。
- ワールド配置範囲・信号と敵の生成。
- 1秒前進で25座標、燃料10.5消費、1秒旋回で1.8rad。
- 自動前進、近距離での調査可否、調査済み再利用禁止、固定施設の全量補給、起点の補給。
- 起点での速度・燃料強化、起点外で購入禁止。
- 燃料切れによる帰還と資金・強化保持、JSON保存、世界リセット。
- ネイティブButtonホールド／トグル、操作で移動、調査操作でイベント、HUDとゲーム状態の一致。

## 画像証拠

- `evidence/godot_initial.png`：起点からの表示（配布ZIP内）。
- `evidence/godot_near_signal.png`：調査可能な12単位まで接近（テスト専用に座標を設定、配布ZIP内）。
- `evidence/godot_inspected.png`：調査イベントを実行した状態（テスト専用、配布ZIP内）。
- `evidence/godot_initial_preview.jpg`：配布ZIP内の軽量プレビュー。画像はGitHubに未格納（GitHubの検証結果はJSON・Markdown）。

## 未確認・制限

1. HTML版の実際の画面を同じ環境で起動してピクセル比較したわけではない。描画の細部・発光・フォントは差分がある。
2. 全368地点の座標／141敵の全フィールドについてHTMLとの照合試験は未実施（初期信号位置のみ厳密照合）。
3. UIに関して、ボタン連動のプログラム試験は通過したが、タッチパネル実機・iPhone縦画面・Windows本体の動作は未検証。
4. 端末ごとに異なるセーブ領域。HTMLのlocalStorageからの移行は未実装。
5. 30分以上の長時間プレイ、敵すべての巡回挙動、極遠方探索の描画負荷、FPS等のベンチマークは未計測。
6. Godot 4.7.2のGUIを全てエディタ上で組み上げる手順や、エクスポートテンプレートの導入は対象外。

**この報告で「通過」と記載するのは実際に実行したチェックだけ**。ゲームの完成・全面移行・最終仕様確定を宣言しない。
