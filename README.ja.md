[English](./README.md) | 日本語

# swift-analytics-firebase

アプリの計測イベントを Firebase（GA4）へ送り、GA4 が黙って捨てるものはその手前で止める。ダッシュボードから数字が静かに消えることがなくなる。

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014%20%7C%20tvOS%2017%20%7C%20watchOS%2010%20%7C%20visionOS%201-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

[swift-analytics](https://github.com/no-problem-dev/swift-analytics) の `AnalyticsClient` の実装です。
本体から切り離してあるのは、SwiftPM が依存をパッケージ単位で解決するからです。
アダプタを本体に同居させると、語彙しか使わない消費者（ドメイン層・プレビュー・テスト）にも
Firebase の SDK が降ってきます。ターゲットを分けても解決は分けられません。

## 特徴

- **GA4 が黙って捨てるものを送らない。** 名前・パラメータ数・文字列の長さを、GA4 の公表制約に
  照らしてから SDK に渡します
- **気づける場所で騒ぎ、出荷後は黙る。** 既定は DEBUG で停止・RELEASE では送らずに見送りです。
  開発中に必ず気づき、出荷したアプリを計測のために落とすことはありません。扱いは差し替えられます
- **IDFA を集めない。** 依存は `FirebaseAnalytics` だけで、IDFA 収集を有効にする
  `FirebaseAnalyticsIdentitySupport` を意図的に足していません
- **`track` 1 回が GA4 の 1 イベント。** このクライアントは履歴を持ちません。間引きは
  `DedupingAnalytics` の仕事です

## クイックスタート

```swift
import AnalyticsCore
import AnalyticsFirebase

FirebaseApp.configure()

#if DEBUG
let analytics = DedupingAnalytics(MultiplexAnalytics([
    ConsoleAnalytics(),
    FirebaseAnalyticsClient()
]))
#else
let analytics = DedupingAnalytics(FirebaseAnalyticsClient())
#endif
```

送信は撃ちっぱなしです。呼び出しは Firebase SDK に渡してすぐ返り、SDK は独自の周期でまとめて
アップロードします。**呼び出しが返ったことは、届いたことではありません。**

### 何を確かめ、破ったらどうなるか

**GA4 は制約を破った送信をエラーも返さずに捨てます。** SDK は成功を返し、アプリからは何も
起きていないように見えるので、ダッシュボードに数字が出ないことでしか気づけません。しかもそれは
「まだ誰も使っていない」とも読めるので、気づかないまま出荷されます。

| 制約 | 上限 |
|---|---|
| 名前の長さ（イベント・パラメータ・ユーザー属性に共通） | 40 文字 |
| 名前に使える文字 | ASCII の英数字と `_`。先頭は英字 |
| 予約接頭辞（あらゆる名前で拒否） | `firebase_` / `google_` / `ga_` |
| Firebase 自身が使うイベント名（イベント名でのみ拒否） | `first_open` / `session_start` ほか 30 件 |
| 1 イベントのパラメータ数 | 25 個 |
| 文字列の値の長さ（数値は測りません） | 100 文字 |

**切り詰めも書き換えもしません。** どれか 1 つでも破った送信は丸ごと落とし、報告されるのは
最初に破った 1 件だけです。既定は DEBUG で停止・RELEASE では黙って見送りで、報告に差し替えられます。

```swift
FirebaseAnalyticsClient(onViolation: { violation in
    reporter.record(violation)
})
```

## ドキュメント

このパッケージの API リファレンスは
[**swift-analytics-firebase**](https://no-problem-dev.github.io/swift-analytics-firebase/documentation/analyticsfirebase) にあります。

このパッケージが実装している語彙（出来事・値・種別・数え方）の文書は
[**swift-analytics**](https://no-problem-dev.github.io/swift-analytics/documentation/) にあります。

## 導入

```swift
.package(url: "https://github.com/no-problem-dev/swift-analytics-firebase.git", .upToNextMinor(from: "0.1.0"))
```

`firebase-ios-sdk` と、それ経由で `swift-analytics` が入ります。`AnalyticsFirebase` プロダクトは
送信先を組み立てる 1 ターゲットにだけ足してください。それ以外の場所から import しません。

## 動作環境

- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / watchOS 10.0+ / visionOS 1.0+
- Swift 6.2+
- 構成済みの `FirebaseApp`

## ライセンス

MIT — [LICENSE](LICENSE) を参照してください。
