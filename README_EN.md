English | [日本語](./README.md)

# swift-analytics-firebase

Firebase Analytics (GA4) implementation of
[swift-analytics](https://github.com/no-problem-dev/swift-analytics).

**It lives apart from the core because SwiftPM resolves dependencies per package.** Bundling the
adapter with the core would pull the Firebase SDK into consumers that only use the vocabulary —
domain layers, previews, tests. Splitting targets does not split resolution.

## Installation

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

## Constraints are checked before sending

**GA4 silently drops events that break its rules.** The SDK reports success, the app sees nothing
wrong, and the only symptom is a number that never appears on the dashboard — which also reads as
"nobody used this feature yet". So it ships unnoticed.

`GA4Dialect` checks, before sending:

| Rule | If broken |
|---|---|
| Event and parameter names ≤ 40 chars | silently dropped |
| Names: leading letter, alphanumerics and `_` only | silently dropped |
| `firebase_` / `google_` / `ga_` prefixes | silently dropped |
| Reserved event names (`first_open`, `session_start`, …) | silently dropped |
| ≤ 25 parameters | silently dropped |
| String values ≤ 100 chars | truncated |

By default it **traps in DEBUG and skips the send in RELEASE**. Analytics never crashes a shipped
app, but during development you cannot miss it. The behaviour is injectable.

```swift
FirebaseAnalyticsClient(onViolation: { violation in
    reporter.record(violation)
})
```

## About IDFA

The SPM product is `FirebaseAnalytics` only — **`FirebaseAnalyticsIdentitySupport` is deliberately
absent**. In firebase-ios-sdk 12.x, `FirebaseAnalytics` does not collect IDFA by default; adding
Identity is what turns it on.

In other words, **not adding it is the specification.** Do not "clean up" by adding it back.

## License

MIT
