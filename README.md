# cloud-probe

**AIクラウド世界を探索するゲーム「CLOUD / PROBE」** の試作・開発リポジトリ。

未知の空間を自由な方角へ進み、発見と探索の成果で成長し、さらに遠くへ進むゲーム。現在はGodotで全体模型の土台を制作中です。数値・世界観・発展機能の採否は検討中です。

## 現在の制作対象：Godot全体模型 v0.2

- **[Godotの本体](godot-foundation/README.md)** — Godotで `godot-foundation/project.godot` を読み込み、F5で起動。
- 探索・遠近自動戦闘・成長・施設建設・出発選択・交易・調査派遣・記録・途中保存を接続。
- **[設計と制作記録の入口](docs/godot-foundation/README.md)** — 設計図、制作手順、調査履歴、検証ログと画面、操作案内。
- 処理36項目＋UI5項目をローカルで確認。10000までの通常攻略と長期バランスはこれから。
- `godot/` は以前のHTML比較版。今回継続して育てる土台は **`godot-foundation/`** です。

## 以前のHTML試作

- **[CLOUD / PROBE 05（index.html）](index.html)** — 以前の操作できるHTML試作版。HTML/CSS/JavaScript + Canvas 2Dの単一ファイル。外部ゲームエンジン不要。
- タッチ操作は2段6ボタン。前進・自動前進／左旋回・後退・右旋回・調べる。
- `index.html` のGitHub上のコード表示はゲーム実行画面ではない。iPhone等で直接遊ぶ公開URLの設定（GitHub Pages等）は別途必要。

## 資料の案内

| ファイル | 役割 |
| --- | --- |
| **[Godot全体模型の資料](docs/godot-foundation/README.md)** | 全体設計・手順・検証・操作案内 |
| **[STATUS.md](STATUS.md)** | 実装済み・確認済み・既知の問題・現在の作業状況 |
| **[docs/CANDIDATES.md](docs/CANDIDATES.md)** | 未実装の機能候補、今後の検討事項 |
| **[HISTORY.md](HISTORY.md)** | 構想からGodot全体模型までの時系列と制作・検証の経緯 |
| **[DECISIONS.md](DECISIONS.md)** | 方向性の確認・試作上の仮採用・未決定事項 |
| **[docs/WORKING_RULES.md](docs/WORKING_RULES.md)** | 共通ルールのひな型（現在は未設定） |
| **[Chappy.md](Chappy.md)** | 通常チャッピー用の短い入口 |
| **[AGENTS.md](AGENTS.md)** | Codex用の短い入口 |

試作中の各数値、ゲームのジャンル、未実装候補の採否は確定していない。**探索の繰り返しがメイン**という構想を軸に検証する。
