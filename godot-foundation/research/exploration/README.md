# CLOUD / PROBE｜探索・世界システム研究

**状態：実行可能な独立研究試作。採用未決定。**

ベース：`main` の Foundation v0.3（`f612435b7aa1c05be607bdb975d123367eaa4819`）。研究ブランチ：`research/exploration-20261107`。本編 `Main.tscn`、`index.html`、旧 `godot/`、共通の `STATUS.md` / `DECISIONS.md` / `HISTORY.md` は変更していません。

## 遊び方

Godot 4.7.2で `godot-foundation/project.godot` を開き、`research/exploration/ExplorationLab.tscn` を **F6で現在のシーンとして実行**。本編のF5起動とは独立します。

CLI: `godot --path godot-foundation --scene res://research/exploration/ExplorationLab.tscn`

- WASD／矢印：研究専用移動。燃料・戦闘・速度155は本編の仕様ではありません。
- 地図をクリック：経由地点を追加し、追加順に航路の線を引く（自動操縦はしません）。
- ボタン：出撃更新、半径900の仮スキャン、現在地記録、航路消去、保存、再読込、起点復帰、ズーム。
- N / E / M / F5 / F9：出撃更新／スキャン／現在地メモ／保存／読込。ホイール：ズーム。
- 青緑の区画：通過済み。濃い青：未知。淡い青：情報入手のみ。金色：固定施設・経由地点・航路。
- 動的光・信号・敵は現在地の探知範囲内だけ表示します。

研究用スキャンは無料、記録上限は地点80・航路80節・軌跡500点、いずれも仮値。研究結果から本番仕様を決める段階ではありません。

## 保存と作業の隔離

研究ファイルは `godot-foundation/.local/exploration_lab.json`。**本編 `campaign.json` は読み書きしません**。既存の `Campaign.settings["exploration_lab"]` に記録を収納し、`Storage.write()` の既存スキーマを利用します。出撃更新では動的対象だけ再生成し、既知施設・踏破区画・経由点・航路を保持。

このブランチに追加したのは `godot-foundation/research/exploration/` 以下のみ。共通ファイルや他担当の作業領域を変更しません。

## テスト

```bash
godot --headless --path godot-foundation --script res://research/exploration/tests/test_exploration.gd
godot --headless --path godot-foundation --script res://research/exploration/tests/test_exploration_ui.gd
godot --headless --path godot-foundation --script res://research/exploration/tests/bench_exploration.gd
```

専用のLinux一時ワークスペースで、Foundationの実際の `world.gd` / `storage.gd` / `campaign.gd` / `catalog.gd` のGit blob一致コピーを使い、**処理24/24・UI状態8/8 PASS**。GUIはXvfb仮想画面＋Godot OpenGL互換描画でレンダリング確認。スクリーンショットは研究成果ZIPへ同梱。画像用fixtureは座標注入したもので、通常プレイ達成記録ではありません。

依存はGodot標準 Control、CanvasItem描画、SceneTree、InputEvent、JSON/FileAccess、Resource、Vector2、RandomNumberGenerator。追加アドオン不要。

実施結果、限界、統合ポイントは [REPORT.md](REPORT.md) を参照。
