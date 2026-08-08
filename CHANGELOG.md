# Changelog

Keep a Changelog 形式。バージョンはタグと一致させる。

## [0.1.0] - 2026-08-09

最初の公開。

### 入っているもの

- `FirebaseAnalyticsClient` — `swift-analytics` の `AnalyticsClient` を Firebase Analytics で実装する
- `GA4Dialect` — **送る前に** GA4 の制約（名前・予約語・パラメータ数・値長）を検査する。
  GA4 は違反を黙って捨てるので、出ないことでしか気づけない。
  既定は DEBUG で停止・RELEASE では送らずに見送る

### 決めていること

- SPM プロダクトは `FirebaseAnalytics` のみ。**`FirebaseAnalyticsIdentitySupport` を足さないことが仕様**
  （firebase-ios-sdk 12.x では、足したときだけ IDFA を集める）
