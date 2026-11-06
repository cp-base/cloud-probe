# cloud-probe

**AIクラウド世界を探索するゲーム「CLOUD / PROBE」** の試作・開発リポジトリ。

未知の空間を自由な方角へ進み、光る信号へ近づいて調査・補給し、燃料が尽きたら起点から再挑戦する。探索の成果で航行能力を強化し、さらに遠くへ進む。交易・行商人・仲間・施設などは、現段階では追加候補。

## ゲーム本体

- **[CLOUD / PROBE 05（index.html）](index.html)** — 現在の操作できる試作版。HTML/CSS/JavaScript + Canvas 2Dの単一ファイル。外部ゲームエンジン不要。
- タッチ操作は2段6ボタン。前進・自動前進／左旋回・後退・右旋回・調べる。
- `index.html` のGitHub上のコード表示はゲーム実行画面ではない。iPhone等で直接遊ぶ公開URLの設定（GitHub Pages等）は別途必要。

## 資料の案内

| ファイル | 役割 |
| --- | --- |
| **[STATUS.md](STATUS.md)** | 実装済み・確認済み・既知の問題・現在の作業状況 |
| **[docs/CANDIDATES.md](docs/CANDIDATES.md)** | 未実装の機能候補、今後の検討事項 |
| **[HISTORY.md](HISTORY.md)** | 構想からVer.5までの時系列と制作・検証の経緯 |
| **[DECISIONS.md](DECISIONS.md)** | 方向性の確認・試作上の仮採用・未決定事項 |
| **[docs/WORKING_RULES.md](docs/WORKING_RULES.md)** | 共通ルールのひな型（現在は未設定） |
| **[Chappy.md](Chappy.md)** | 通常チャッピー用の短い入口 |
| **[AGENTS.md](AGENTS.md)** | Codex用の短い入口 |

試作中の各数値、ゲームのジャンル、未実装候補の採否は確定していない。**探索の繰り返しがメイン**という構想を軸に検証する。
