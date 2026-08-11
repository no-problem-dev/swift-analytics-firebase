# Changelog

## [Unreleased]


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