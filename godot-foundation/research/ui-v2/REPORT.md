# CLOUD / PROBE｜UI・操作画面研究（2代目）

- 実施日：2026-11-07（JST）
- 対象：Foundation v0.3 / Godot 4.7.2-stable
- 研究ブランチ：`research/ui-v2`
- 基点：`main` の commit `f612435b7aa1c05be607bdb975d123367eaa4819`
- 状態：**動作試作・独立検証完了／本番採否は未決定**
- 初代の `research/ui`、`main`、HTMLの `index.html`、旧 `godot/`、共有 `STATUS.md`・`DECISIONS.md`・`HISTORY.md` は変更していない。

## 1. 実装の対象と方法

今回の起点 `main` には `ui/main.gd` がHUD、施設5タブ、地図、設定、入力ボタンをコードで組み立てるFoundation v0.3がある。初代 `research/ui` で作成されたシーン化UI（83項目のCI確認済）を**初代ブランチを変更せず**、GitHub上のblobから2代目専用ブランチへ転用した。その上で狭幅の応答表示、実マウス操作、画像検証を独立追加した。最初から別の作り直しにはしていない。

使ったGodot標準機能：`CanvasLayer`、`Control`、`PanelContainer`、`VBoxContainer`、`HBoxContainer`、`HFlowContainer`、`TabContainer`、`Theme`、`StyleBoxFlat`、`SystemFont`、`PackedScene`、`SubViewport`、入力シグナル、`Viewport.push_input()`、`RenderingServer.frame_post_draw`。

依存する既存部品：`ui/main.gd`、`ui/map_view.gd`、`core/session.gd`、`data/catalog.gd`、`Main.tscn`。関連資料：`Chappy.md`、`godot-foundation/README.md`、`docs/godot-foundation/README.md`、同ディレクトリ内の設計図・制作手順・検証記録。参考Godot公式： [Theme](https://docs.godotengine.org/en/stable/tutorials/ui/gui_skinning.html)、[HFlowContainer](https://docs.godotengine.org/en/stable/classes/class_hflowcontainer.html)、[GUI containers](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html)。

## 2. 実装・変更ファイル

| 対象ファイル | 機能・影響 |
| --- | --- |
| `Main.tscn` | main.gdの代わりに研究アダプタをスクリプト指定する入口変更。 |
| `ui/research_ui_main.gd` | `ui/main.gd` 継承。既存Session・描画・ルール・保存・施設コールバックを保ちUIの構築だけ差し替え。 |
| `ui/layouts/hud.tscn` | HUDをエディタで編集できるノードに分割。 |
| `ui/layouts/modal_shell.tscn` | 設定、施設、地図等の共通モーダル外殻。 |
| `ui/theme/cloud_probe_theme.tres` | 背景・ボタン・枠・余白を共通化。日本語のOSシステムフォント候補を追加。 |
| `ui/layouts/hud_adaptive.gd` | 2代目追加。解像度に応じた3モード、ミニマップと補助文字の表示制御、状態行の高さを確保。 |
| `ui/layouts/modal_adaptive.gd` | 2代目追加。狭幅時のモーダル余白・見出し・閉じるボタン調整。 |
| `tests/ui_layout_smoke.gd` / `tests/ui_foundation_integration.gd` / `tests/ui_capture.gd` | 初代の再利用テストとプレビュー作成。 |
| `tests/ui_compact_smoke.gd` | 2代目追加。4解像度の配置・動線テスト。 |
| `tests/ui_mouse_smoke.gd` | 2代目追加。SubViewportへの実マウス押下・解除で地図/前進ボタンを検証。 |
| `tests/ui_v2_capture.gd` / `tests/ui_live_capture.gd` | サンプルUIの画像と、実Foundation準備・航行シーンの実描画証拠を再現。 |
| `.github/workflows/ui-v2.yml` | 2代目ブランチ専用CI。Godot 4.7.2のimport、回帰、マウス操作、画像artifact、source ZIPを生成。 |
| `research/ui-v2/REPORT.md`、`EVIDENCE.md`、`evidence/ci-results.txt` | 経緯、実測、再現方法、課題と導入評価。 |

`core/`、`data/`、`visuals/`、既存 `ui/main.gd` は変更していない。

## 3. レスポンシブUIの仮設定

- `wide`：横850px以上かつ縦650px以上。既存HUDのタイトル、ミニマップ、操作ボタン、補助案内を表示する。
- `compact`：横850px未満または縦650px未満。ミニマップと長い補助説明を隠す。地図画面は上部の「地図・記録」ボタンから開ける。
- `tiny`：横700px未満または縦530px未満。さらにヘッダー題名とキー案内を省略し、状態表示・上部5操作・下部5操作を残す。
- `HFlowContainer` により横幅が足りないときのボタン列を折り返す。Top/Bottomパネルはアンカーを維持し、サイズ別に高さだけ調整。
- モーダルはcompactで上下左右の余白を縮小。中の施設5タブは既存処理をそのまま利用する。
- これは**研究用仮案**。本番仕様として確定していない。

## 4. 実行・検証

**GitHub Actions：** [成功run 42304817753](https://github.com/cp-base/cloud-probe/actions/runs/42304817753) ／ Godot 4.7.2でリポジトリ実体をcheckout・import・headless実行。

| 検査群 | 実測 |
| --- | ---: |
| 初代レイアウトの継承検査（800/1180/1920） | 23/23 |
| 2代目レイアウト検査（640/800/1180/1920、状態行高さ・モーダル） | 51/51 |
| SubViewportマウス操作（地図クリック、前進押下/解除、2解像度） | 10/10 |
| 実Foundation連携（HUD、施設5タブ、地図、設定、前進） | 12/12 |
| 既存Foundation UI回帰 | 6/6 |
| 既存ゲーム処理回帰 | 42/42 |
| **合計** | **144/144、失敗0** |

CIの画像生成：HUD4サイズ+640px施設メニュー1枚＝**5枚、保存失敗0**。ただしGitHub ActionsのUbuntu標準環境には日本語フォントがなく、**CI artifact画像の日本語は豆腐表示**。CIコード検証には影響しないが、この画像だけで最終外観を評価しないこと。

**独立ローカル実行：** 同CIが `git archive` で生成したFoundationソースZIPを、別の一時ワークスペースへ展開。ライブラリ `/ツール倉庫/Godot/Godot_v4.7.2-stable_linux.x86_64.zip` から取得したGodot実体 `4.7.2.stable.official.ed1daf0bf` でimportし、前記144項目を**ローカルでも全件合格**。Noto Sans CJK JPが導入済みのLinux環境でXvfb+OpenGL互換レンダラを使い、**サンプルUI5枚＋実Foundation準備1枚・出発後航行1枚＝計7枚を画像化**。画像を目視確認し、日本語・情報欄・施設5タブ・HUD・ミニマップが描画された。実Foundationの出発は検証スクリプトから既存の `_depart("base")` を呼び、`docked → travel` を確認した。サンプル画像はテスト値、実Foundation画像は起動したゲーム状態であり区別する。保存破壊防止のためテストで `allow_save=false` とする。

操作入力テストはSubViewportに実マウスイベントを渡したもの。**人間がF5で長時間遊んだことを意味しない**。10000深度までの攻略、継続プレイ、実機Windows、実パッド操作は未検証。

## 5. 発見と修復

1. 当初、`layout_mode` という変数がネイティブ `Control.layout_mode` と衝突し、Godot parse error。研究専用 `ui_size_mode` に変更して再実行し解消。
2. `Label.clip_text=true` と自動折り返しでHUD状態行の高さが0になり、画像上から消失。クリップを外し最低高22/40pxを確保し修復。
3. CI標準Ubuntuでは日本語フォント欠落を検出。`Theme` に `SystemFont` フォールバック名を設定し、Noto CJKがあるLinux環境で実描画成功。**OSに日本語フォントがない場合は残る環境依存**。CIへ追加フォントを入れる実験ではapt取得が進まず、検査本体は外部フォント配布に依存しない構成とした。
4. XvfbのVulkan初期化は一部環境で失敗し、OpenGL3へフォールバック。動作画像はOpenGL互換方式で取得。ALSA音声出力はダミーに切替、UI/操作の結果には影響なし。

## 6. 現状比較と導入評価

| 観点 | mainのFoundation | 2代目試作 |
| --- | --- | --- |
| 画面変更 | `ui/main.gd` のUI生成関数と座標値を編集 | `.tscn` 階層・Theme・専用レイアウトScriptに役割分割 |
| 共通デザイン | 個々のStyleBox/個別テーマ設定 | 共通Theme resource |
| 小画面 | 固定幅に依存しやすい | 640×480を含む4サイズで描画・配置・イベントを検証 |
| 再利用 | 画面本体はコードで毎回生成 | HUDシーンとモーダル外殻を再利用（施設タブ内部は依然動的） |
| ChatGPT改修 | UI大関数に密集、部分修正の影響見積もりが難しい | node path / scene / controller / testsが別ファイルで差分管理容易。ただしNodePathを変更すると接続が壊れる |
| 進行ルール | Foundation v0.3 | **変更なし**。Sessionを継承利用 |

**導入難度：中。** `Main.tscn` のscript指定、研究アダプタ、HUD/Modal各シーンとLayout Script、Themeを一式移植する必要がある。既存実装に戻す際は `Main.tscn` の参照先を `res://ui/main.gd` に戻せる。すべての施設内部UIをシーン化するにはさらに工数が必要。

今後の候補：施設タブ内の固定幅（例：480px選択欄）の最小幅対策、実Windows画面操作、キーボード/パッドによるfocus移動、高DPI、長文折り返しとモーダル内容のスクロール、F5操作による準備→航行→施設→改修→保存→再開の通し試遊。すべて**提案・未採用**。本番へのマージは行わない。
