# CLOUD / PROBE — v0.2のGitHub共有記録

> 共有版：PC固有のユーザーパスを一般化しています。旧模型のパスは当時の履歴です。現在の本体はリポジトリの `godot-foundation/`。
実施：2026-11-07。ユーザーの「Githubにも置いて、記録も共有できるように」という依頼で反映。

- リポジトリ：[cp-base/cloud-probe](https://github.com/cp-base/cloud-probe)
- ブランチ：`main`
- コミット：[f52debcb978faa0c032eca9dd322e0d061c49a6d](https://github.com/cp-base/cloud-probe/commit/f52debcb978faa0c032eca9dd322e0d061c49a6d)
- 模型の本体：[godot-foundation](https://github.com/cp-base/cloud-probe/tree/main/godot-foundation)
- 設計・制作記録の入口：[docs/godot-foundation](https://github.com/cp-base/cloud-probe/blob/main/docs/godot-foundation/README.md)

## 共有したもの

- Godotのソース、Resource、シェーダー、処理・UI・表示用検査。
- 設計図、制作手順、調査履歴、起動・操作案内、検証記録。
- 処理・UIのログと、それぞれの文書から参照されるゲーム画面16枚。
- README、STATUS、履歴、判断記録、候補一覧、AGENTSとChappyの既存入口への案内。

共有版ではPC固有のユーザーパスと起動案内を一般化した。元のローカル文書と現在のプレイ進行は保持。
進行保存・検査用保存・Godotキャッシュは共有していない。旧HTML・Godot比較版・共通ルールのひな型は保持した。

## 確認したこと

- 共有用構成から新規インポートし、処理36項目＋UI5項目を再実行して通過。
- 相対リンクが、共有ファイルまたは既存リポジトリ内のファイルへ到達することを確認。
- GitHubの新しいtreeで、共有した75ファイルのGit blob SHAが準備した内容と一致。
- 今回変更しない既存25ファイルのSHAが元のままであることを確認。
- `main`が上記コミットを指すことを反映後に取得。
- GitHubからREADME、共有資料の入口、project.godot、core/session.gdを再取得し、内容が一致。

これはGitHubへの配置・内容確認の記録。別の担当が実際に読んだことや、別PCで試遊したことまでは確認していない。
