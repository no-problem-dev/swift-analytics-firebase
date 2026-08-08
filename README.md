[English](./README_EN.md) | 日本語

# swift-analytics-firebase

[swift-analytics](https://github.com/no-problem-dev/swift-analytics) の
Firebase Analytics（GA4）実装。

**本体から切り離してあるのは、SwiftPM が依存をパッケージ単位で解決するから。**
アダプタを本体に同居させると、語彙しか使わない消費者（ドメイン層・プレビュー・テスト）にも
Firebase の SDK が降ってきます。ターゲットを分けても解決は分けられません。

## 導入

```swift
.package(url: "https://github.com/no-problem-dev/swift-analytics-firebase.git", from: "0.1.0")
```

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

## 送る前に制約を確かめます

**GA4 は制約を破った送信を黙って捨てます。** SDK は成功を返し、アプリからは何も起きていない
ように見えるので、ダッシュボードに数字が出ないことでしか気づけません。しかもそれは
「まだ誰も使っていない」とも読めるので、気づかないまま出荷されます。

`GA4Dialect` が送る前に見るもの:

| 制約 | 破ると |
|---|---|
| イベント名・パラメータ名 40 字 | 黙って捨てられる |
| 名前は英字で始まる英数字と `_` のみ | 同上 |
| `firebase_` / `google_` / `ga_` 接頭辞 | 同上 |
| 予約イベント名（`first_open` `session_start` ほか） | 同上 |
| パラメータ 25 個 | 同上 |
| 文字列の値 100 字 | 超えた分が切れる |

既定では **DEBUG で停止、RELEASE では送らずに見送ります**。出荷後に計測のためにアプリを
落とすことはしませんが、開発中は止まるので出荷までに気づけます。扱いは差し替えられます。

```swift
FirebaseAnalyticsClient(onViolation: { violation in
    reporter.record(violation)
})
```

## IDFA について

SPM プロダクトは `FirebaseAnalytics` だけを足し、**`FirebaseAnalyticsIdentitySupport` を
足しません**。firebase-ios-sdk 12.x では `FirebaseAnalytics` が既定で IDFA を集めず、
Identity を足したときだけ集めます。

つまり**「足さないこと」が仕様**です。依存を整理するときに「使っていないから」と
消さないでください（消せるものはありませんが、足さないことを忘れないでください）。

## ライセンス

MIT
