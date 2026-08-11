# CONSISTENCY — 標準からの意図的な逸脱

ファミリー様式規約に従っていない箇所を、理由付きで宣言する。

## `docc.yml` が Swift-DocC プラグインを使わない

**条項**: 標準ワークフローの `docc.yml` は `swift package generate-documentation` でドキュメントを作る。

**逸脱内容**: このリポジトリの `docc.yml` は、ビルド中に `-emit-symbol-graph` でシンボルグラフを書き出し、
`docc convert` を直接呼ぶ。プラグインは通らない。

**理由**: プラグインはシンボル抽出を `swift-symbolgraph-extract` に任せるが、
**SwiftPM はその起動コマンドにバイナリ xcframework 依存のフレームワーク検索パスを入れない。**
FirebaseAnalytics は xcframework で配られ、スライスの場所は
`-I …/FirebaseAnalytics.xcframework/macos-arm64_x86_64` として渡される。
しかし中身は `framework module FirebaseAnalytics` であり、Clang はフレームワークモジュールを
`-F` でしか見つけられない。だから**コンパイルは通るのに抽出だけが落ちる** ——
コンパイル側には、SwiftPM が framework を複製したビルドディレクトリを指す `-F` が渡っている。

この差は外から埋められない。`-Xswiftc` も `-Xcc` も、ターゲットの `swiftSettings` も、
`swift-symbolgraph-extract` の引数には届かない（2026-08-11 に3つとも実測）。
一方 `-emit-symbol-graph` はビルドの中で動くので、検索パスは最初から正しい。

出てくるシンボルグラフは、抽出コマンドに手で `-F` を足したときの結果と同一
（公開シンボル 27・関係 33・precise identifier 完全一致。2026-08-11 実測）。

**Firebase 側の問題ではない。** macOS スライスは正しく配られている。直る場所は SwiftPM で、
そこが `-F` を渡すようになったら標準の書き方に戻す。
