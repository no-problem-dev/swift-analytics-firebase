English | [日本語](./README.ja.md)

# swift-analytics-firebase

The Firebase Analytics (GA4) destination for [swift-analytics](https://github.com/no-problem-dev/swift-analytics).

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014%20%7C%20tvOS%2017%20%7C%20watchOS%2010%20%7C%20visionOS%201-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

It lives apart from the core because SwiftPM resolves dependencies per package: bundling the adapter
with the vocabulary would pull the Firebase SDK into every consumer that only uses the vocabulary —
domain layers, previews, tests. Splitting targets does not split resolution.

## Features

- **Refuses what GA4 would silently discard.** Every name, parameter count, and string value is
  checked against the published GA4 limits before anything reaches the SDK
- **The refusal is loud where it should be.** The default handling traps the process in debug builds
  and stays silent in release, so a violation is met during development and never crashes a shipped
  app. The handling is injectable
- **No IDFA.** The package depends on `FirebaseAnalytics` alone and deliberately omits
  `FirebaseAnalyticsIdentitySupport`, which is what would turn IDFA collection on
- **One `track` call is one GA4 event.** This client keeps no history of its own; deduplication is
  `DedupingAnalytics`'s job

## Quick Start

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

Sending is fire-and-forget. The call hands the payload to the Firebase SDK and returns immediately;
the SDK batches and uploads on its own schedule, so a returned call is not a delivered event.

### What is checked, and what happens when it fails

GA4 discards a payload that breaks its limits **without reporting an error** — the SDK call
succeeds, the app sees nothing wrong, and the only symptom is a number that never appears on the
dashboard. That also reads as "nobody has used this yet", so it ships unnoticed.

| Rule | Limit |
|---|---|
| Name length — events, parameters, and user properties alike | 40 characters |
| Characters in a name | ASCII letters, digits and `_`; first character must be a letter |
| Reserved prefixes, refused on every kind of name | `firebase_`, `google_`, `ga_` |
| Firebase's own event names, refused as event names only | `first_open`, `session_start`, and 30 more |
| Parameters on one event | 25 |
| String value length (numeric values are not measured) | 100 characters |

**Nothing is truncated or rewritten.** A payload that breaks any rule is dropped whole, and
validation reports only the first rule it broke. Default handling traps in debug and is silent in
release; substitute your own to report instead:

```swift
FirebaseAnalyticsClient(onViolation: { violation in
    reporter.record(violation)
})
```

## Documentation

The vocabulary this package implements — events, values, kinds, and counting rules — is documented
at [**swift-analytics**](https://no-problem-dev.github.io/swift-analytics/documentation/).

This package publishes no DocC site of its own: `swift-symbolgraph-extract` cannot read
`AnalyticsFirebase` on macOS, because Firebase Analytics ships as an xcframework whose macOS module
is not exposed in the form symbol graph extraction needs. The public surface here is two types, and
both are documented in the source. See [CONSISTENCY.md](CONSISTENCY.md).

## Installation

```swift
.package(url: "https://github.com/no-problem-dev/swift-analytics-firebase.git", .upToNextMinor(from: "0.1.0"))
```

The package brings in `firebase-ios-sdk` and, through it, `swift-analytics`. Add the
`AnalyticsFirebase` product to the one target that composes your destinations — nothing else in the
app should import it.

## Requirements

- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / watchOS 10.0+ / visionOS 1.0+
- Swift 6.2+
- A configured `FirebaseApp`

## License

MIT — see [LICENSE](LICENSE).
