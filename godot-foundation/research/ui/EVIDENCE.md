# UI研究・証拠一覧

- `evidence/ui-layout-tests.log`: ローカルGodot 4.7.2実行、23/23、3種類の実SubViewport。
- `evidence/ui-adapter-stub.log`: ローカル代替基底クラスでの10/10。実Foundation統合確認ではない。
- `evidence/ui-capture.log`: Xvfb＋Godotの画像保存結果。
- 生成画像3点は別途添付：hud-800.png、hud-1180.png、modal-1180.png。表示値はサンプルであり実プレイの結果を示さない。
- 再生成スクリプト：`../../tests/ui_capture.gd`。実Foundation統合テスト：`../../tests/ui_foundation_integration.gd`。
- 画像のPNG実体は研究ZIPに含め、GitHubには撮影スクリプトと記録テキストを保存する。


## CI完走後の追補

- [GitHub Actions run 42288276201](https://github.com/cp-base/cloud-probe/actions/runs/42288276201)：Godot 4.7.2 / Linux、チェックアウト・インポート・全ステップ成功。
- **新UI 23/23、本体統合12/12、既存UI 6/6、進行処理42/42、計83/83**。いずれも失敗0。
- 全結果は同Runのjob 128134684200ログで確認。研究ブランチの初回実装commitを検証した。
- headless自動テストであり、実ウィンドウの人手操作・長時間プレイの検査ではない。
