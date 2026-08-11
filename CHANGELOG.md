# Changelog

## [Unreleased]

### Fixed

- The DocC site is published again. It had never built: the Swift-DocC plugin extracts symbols with
  `swift-symbolgraph-extract`, and SwiftPM omits the framework search path for binary xcframework
  dependencies from that command, so `FirebaseAnalytics` — a framework module, which Clang finds
  only through `-F` — could not be loaded. The workflow now takes the symbol graph from the
  compiler, where the search paths are already correct, and runs `docc` directly. The graph is
  identical to the extractor's once `-F` is supplied by hand.

### Changed

- `FirebaseAnalyticsClient`'s documentation refers to `DedupingAnalytics` as plain code rather than
  a symbol link. It lives in another module, so the link never resolved.

Keep a Changelog format. Versions match their tags.

## [0.1.0] - 2026-08-09

First public release.

### What's included

- `FirebaseAnalyticsClient` — implements `swift-analytics`'s `AnalyticsClient` on Firebase Analytics
- `GA4Dialect` — checks GA4's constraints (name, reserved words, parameter count, value length)
  **before sending**. GA4 discards violations silently, so the only way you notice is that nothing shows up.
  The default is to halt in DEBUG, and in RELEASE to let it go without sending

### Decisions

- The only SPM product is `FirebaseAnalytics`. **Not adding `FirebaseAnalyticsIdentitySupport` is the specification**
  (in firebase-ios-sdk 12.x, IDFA is collected only when it is added)