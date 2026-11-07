# CLOUD / PROBE — 既存背景エフェクト技法の比較

2026-11-07 / 研究ブランチ `study/space-effects-20261107` / 既存公開ページの独立拡張。

## 研究目的
CLOUD / PROBEの床なし一人称視点に適した下方情報層を、既存の無料シェーダー表現から選ぶ。見た目を決定せず、探索信号の見やすさ・移動時の視差・制作の容易さを比較する。

## 比較モード
- **従来**: v0.3の下方ノイズ・光の流れを保持。
- **情報の海**: CC0「2D Fog Overlay」の多層ノイズ着想。下方で柔らかい光の霧が漂う。
- **光の回路**: CC0「Perspective Grid Animated」の透視グリッド着想。世界座標へ固定し一部を欠損。
- **デジタル残響**: CC0「Scrolling Line Background」の移動ライン着想。断続的な光線と走査を描く。

参考元とライセンス:
- blinks, [2D Fog Overlay](https://godotshaders.com/shader/2d-fog-overlay/) — CC0
- jospic, [Perspective grid animated](https://godotshaders.com/shader/perspective-grid/) — CC0
- SuperMatCat24, [Scrolling Line Background](https://godotshaders.com/shader/scrolling-line-background/) — CC0

## 実装範囲
- `space-study/index.html`: 既存のiPhone向けv0.3のUI・探索操作へ効果切替を追加。
- `space-study/effect_adapter.js`: 表現原理をCanvas2Dへ移植したコード。Godotのオリジナルshaderコードをそのままブラウザで動かしているわけではない。
- 背景選択時の位置・向き・探索信号配置は変更しない。既存の色と背景密度も維持。
- 研究ブランチのため`main`・現在のGitHub Pages版は未変更。既存ページを置き換えるには、十分な検証の後でマージが必要。

## 検証
- 別途作成したローカルの同系統ブラウザ比較模型で、Canvas2Dフォールバックの4モード選択・描画・WASD操作・モバイル相当サイズの画面を確認。JS例外なし。
- この研究ブランチ版はコード反映と静的確認まで。GitHub Pagesからの実機動作、Safari、性能、Godot内での描画は未確認。
- 自動検証ブラウザでWebGL2が利用できず、GPU効果の稼働はまだ確認できない。Godotシェーダーの原文利用にはGodot側での追加作業が必要。

## 観察上の論点
- 情報の海：床に見えにくい一方、広い面で明るさが増す。
- 光の回路：移動方向の手がかりになる一方、物理的な床に見える可能性。
- デジタル残響：断続的で控えめだが、視認性との両立は実機で要比較。
- 採用は未決定。UI改修や遠景構造物の再設計は対象外。
