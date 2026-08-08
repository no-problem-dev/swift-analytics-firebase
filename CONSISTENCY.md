# CONSISTENCY — 標準からの意図的な逸脱

ファミリー様式規約に従っていない箇所を、理由付きで宣言する。

## DocC のワークフローを置いていない

標準は `tests.yml` + `release-on-tag.yml` + `docc.yml` の 3 本だが、このリポジトリは
**`docc.yml` を持たない**。

`swift-symbolgraph-extract` が macOS で `AnalyticsFirebase` を読めずに落ちるため
（`missing required module 'FirebaseAnalytics'`）。Firebase Analytics は xcframework で配られ、
**macOS 向けのモジュールが symbolgraph の抽出に必要な形で出てこない**。
これはこちらのコードの問題ではなく、依存の配布形態の問題で、こちらでは直せない。

落ち続けるワークフローを置くほうが害が大きい —— 赤いのが常態になると、
本当に壊れたときに区別できなくなる。

**代わりに README で説明を完結させている。** このパッケージの公開面は 2 つ
（`FirebaseAnalyticsClient` と `GA4Dialect`）しかなく、doc コメントはソースに書いてある。
語彙そのものの文書は [swift-analytics](https://no-problem-dev.github.io/swift-analytics/) にある。

Firebase 側が macOS のモジュールを出せるようになったら、標準の 3 本に戻す。
