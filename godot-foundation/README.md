# CLOUD / PROBE Foundation v0.2

2026-11-07に作成した、今後継続して育てるGodotの土台です。
旧来の局所模型へ合わせるのではなく、全体設計に合わせて状態・処理・UIを構成しました。
光・床のシェーダーのみ、以前の表示確認済みの部品を引き継いでいます。

ローカルのGodot 4.7.2で `project.godot` を読み込み、F6ではなくF5でゲーム全体を起動します。
追加アセット・プラグイン・ネット接続は不要です。

- 準備画面から出発。前後・旋回はW/S/A/Dまたは矢印キーと画面ボタン。
- 光は近づくと自動回収。敵への砲撃・近接も距離で自動切替。
- Eで近くの施設・特別な信号へアクセス。Mで地図。Spaceで一時停止。
- 失敗時は出発施設へ戻り、資金・改修・施設・記録・荷物は保持する仮仕様です。
- 施設で補給・改修・装備・建設・出発選択・交易1品・調査派遣1枠を扱います。
- 保存は `.local/campaign.json`。航行中の再開は一時停止から始まります。

処理は `core/session.gd`、世界生成は `core/world.gd`、恒久状態は `core/campaign.gd`、保存は `core/storage.gd`。
敵と武器は `data/*.tres` のResource、表示と操作は `ui/`、描画は `visuals/`。
座標は平面のVector2で、表示には暫定的に3Dを使用しています。

検査（Godotの実行ファイルを使う）：

```text
godot --headless --path <このフォルダ> --script res://tests/test_session.gd
godot --headless --path <このフォルダ> --script res://tests/test_ui.gd
```

検査用の保存は `tests/.state/`。遠方・強化後の比較には状態注入を明記して使っています。
`tests/visual_fixture.gd` は実画面の敵4タイプ確認専用で、進行を保存しません。
通常プレイで0から10000に到達するまでのバランス確認はまだ行っていません。

起点近くの光1個は、初期収入が完全に途切れないための仮置きです。
追加発光は初期OFF。世界観、美術、アイテム生成・ドロップの採否は保留です。

## 共有資料

[設計・制作記録の入口](../docs/godot-foundation/README.md)から設計図・手順書・検証記録へ進めます。
旧`godot/`はHTML版との比較試作で、この`godot-foundation/`が今回の全体模型です。
