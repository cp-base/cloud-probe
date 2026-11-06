# 探索・世界システム研究報告

2026-11-07｜Foundation v0.3ベースの独立機能研究｜**本番採用未決定**

## 既存コード・資料の確認

`main` の `Chappy.md` を入口に、`README.md` / `STATUS.md` / `DECISIONS.md` / `godot-foundation/README.md` / `docs/godot-foundation/` および `core/world.gd`、`core/session.gd`、`core/storage.gd`、`core/campaign.gd`、`ui/map_view.gd`、既存テストを確認。

Foundationの世界は `Vector2` 平面座標、480×480の遅延生成区画、半径10000。区画生成は世界seed＋sortie＋区画キーで決まり、一般対象は区画につき最大1。開始直後の光とv0.3追加敵は別枠。固定施設候補10＋起点1の配置は世界seedに固定され、建設・発見・出発登録はCampaign側で維持する。一方、光・信号・敵と区画キャッシュは出撃更新で作り直す。

`World.to_dict()`は出撃ID・生成済み区画・動的対象を保存し、`Storage` は `Vector2` をJSONに詰める。`Session.load_game()` は固定施設をseedから再構成してから保存中の出撃を復元。現在の `Campaign.discoveries` は出撃IDのある動的信号情報も保持するが、航路・通過区画・調査だけで判明した区画を別途管理しない。

## 今回実装した機能

| ファイル | 内容 |
|---|---|
| `exploration_ledger.gd` | 訪問区画、再入域数、情報済み区画、既知／接近施設、手動経由地点、順序付き航路、出撃境界を持つ軌跡 |
| `exploration_lab.gd` / `ExplorationLab.tscn` | 本編と独立した操作可能な地図シーン。探索・地図クリック・スキャン・航路記録・出撃更新・別名保存と再読込 |
| `tests/test_exploration.gd` | 生成不変性、負座標、再訪、保存復元、出撃再生成、旧保存互換など24件 |
| `tests/test_exploration_ui.gd` | 画面構成、クリック、移動、スキャン、保存、出撃、リロードの8件 |
| `tests/bench_exploration.gd` | 広い区画列挙、探索検索、保存サイズの単発測定 |

記録は `Campaign.settings["exploration_lab"]` に格納し、既存のJSONスキーマを変えずに保存できることを検証。**本編のsaveを使わず、`.local/exploration_lab.json`を別作成**。研究用移動速度155・無料スキャン900は本編バランスではない。自動航行も未実装。

## 実施した操作・検証結果

**実行環境**：ユーザーPCとは異なる、会話専用Linux一時ワークスペース。ライブラリのGodot 4.7.2.stable.official.ed1daf0bfを展開して使用。Godot Foundationの `world.gd` / `storage.gd` / `campaign.gd` / `data/catalog.gd` はGit blob SHAが `main` と一致するコピーで実行（完全な本編 `Main.tscn` のGUI統合までは試験していない）。

**世界・永続化24/24 PASS**：同じseed・出撃・区画なら生成順に依存しない、区画の二重生成なし、出撃ID付き対象、踏破・再訪の区別、航路ID検証、10,000境界、スキャン、現在地・区画・動的対象・施設・踏破/情報状態・経由点・航路の保存と再読込、再起動後の二重生成なし、固定施設は次出撃でも一致し動的対象のみ入替、旧保存に記録欄がない場合の空初期化、誤った航路参照除外、負座標の切捨て誤り防止。

**UI構造8/8 PASS**：9ボタン生成、地図クリックによる航路節、移動での踏破、スキャン、保存、次の出撃、旧出撃の再読込をGodot実シーンの状態と入力ハンドラで試験。

**表示実行**：仮想Xディスプレイ上のGodot OpenGL描画で研究シーンを起動し、PNG保存結果 `EVIDENCE_SAVE 0`。表示用fixtureの経由点6・訪問区画3・情報済み区画18・既知施設2を描画。これは座標を注入した描画確認であり、通常のプレイ過程を示さない。PNG実体は同時納品の成果ZIPに保存。

**広域参考計測**：41×41=1681区画 → 動的対象1388、区画生成約13〜16ms、`World.active()` 1000回約300〜325ms、Worldシリアライズ約373,200バイト。単発の環境依存値であり性能保証ではない。現行 `active()` は対象の全件走査、`objects` と `chunks` は出撃中増加する。

## 得られた知見

1. **恒久的な場所と動的遭遇物は別概念**。固定施設ID・区画座標は航路の基準にできるが、出撃IDを含む光・敵・信号は次出撃の同一地点を保証しない。
2. **踏破と情報だけの発見を別に表示**すると、未知区画への進路計画を表現できる。実プレイヤーの主観的な面白さの検証は未実施。
3. `Campaign.settings` に小さな追加辞書を置けば、既存Storageのまま旧セーブに対応可能。ただし本編の保存・UIへ自動統合されたわけではない。
4. 乱数再現・出撃の境界・保存再読込・負座標を独立した自動試験として継続利用できる。

## Foundationへ取り込む場合の影響

- `core/session.gd`：ledgerをsettingsから復元、出撃開始時 `begin_sortie()`、探索中の `world.ensure_nearby()` と `discover()` の後で `record_position()`、スキャン時 `scan_area()`、保存前にsettingsへ反映。いずれも**提案**で、今回の本編コードは変更しない。
- `ui/map_view.gd` と `ui/main.gd`：踏破/情報済み/未知のレイヤと、経由点・航路編集の操作を追加。正式採用時に本編の既存施設UIと接続。
- `Campaign.facility_state` と研究用contactsは本番なら一元化することを提案。永続化の重複を残すべきではない。
- 依存は固定施設ID・World.CHUNK・World.RADIUS・Campaign.settings・Storage.pack/unpackとGodotの標準描画。追加外部アセットなし。

**採用難度（仮評価）**：記録・保存は低〜中、マップ描画への移植は中、本編の探知・速度・燃料・戦闘と合わせて探索体験を仕上げる作業は中〜高。

## 問題・未確認・今後の候補

- 通過した区画だけを踏破と呼ぶか、半径探知済みを踏破とするかは未決定。900スキャン・UI色・地点の上限も仮案。
- 本編の燃料や敵がある状態で地図UIを長時間操作する試遊は未実施。今回の研究ラボの高速移動から実際の難易度を推定しない。
- `Campaign.discoveries` は出撃回数とともに蓄積するため、永続航路へ混ぜない。長期の保存量・全件走査・強制終了時の保護は追加検証候補。
- 航路の距離/費用見積、施設間の到達経路、観測情報の確度、世界縮尺の切替などを次候補として記録。
- `main`、旧HTML/旧Godot、他担当ブランチ、共有 `STATUS.md` / `DECISIONS.md` / `HISTORY.md` は無変更。統合・採用判断は別工程。
