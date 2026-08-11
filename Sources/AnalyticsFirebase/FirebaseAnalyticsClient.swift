import AnalyticsCore
import FirebaseAnalytics
import Foundation

/// Sends measurement to Firebase Analytics, refusing anything GA4 would silently discard.
///
/// **This is the only type that knows which vendor is behind the measurement.** Sending is
/// fire-and-forget: the call hands the payload to the Firebase SDK and returns straight away.
/// The SDK batches events and uploads them on its own schedule, so a returning call is not a
/// delivered event, and there is no completion, no result and no way to confirm delivery from
/// here. Nothing retries and nothing reports errors — measurement must not hold up the app.
///
/// ## Usage
///
/// ```swift
/// FirebaseApp.configure()
///
/// #if DEBUG
/// let analytics = DedupingAnalytics(MultiplexAnalytics([
///     ConsoleAnalytics(),
///     FirebaseAnalyticsClient()
/// ]))
/// #else
/// let analytics = DedupingAnalytics(FirebaseAnalyticsClient())
/// #endif
/// ```
///
/// ## What is checked before sending
///
/// A payload that breaks a GA4 limit **looks like it was sent and is then discarded**, and the
/// only symptom is a number missing from the dashboard. ``GA4Dialect`` holds the name and value
/// rules; a payload that breaks one is never handed to Firebase, and the mistake is made loud
/// during development rather than found weeks later on the dashboard.
///
/// ## What counts as one event
///
/// One call to ``track(_:)`` is one Firebase event. This client keeps no history and suppresses
/// nothing of its own, so "once per session" and "once per install" only mean anything when
/// ``AnalyticsCore/DedupingAnalytics`` wraps it.
public struct FirebaseAnalyticsClient: AnalyticsClient {

    private let onViolation: @Sendable (GA4Dialect.Violation) -> Void

    /// - Parameter onViolation: What to do about a payload GA4 would discard. It is dropped either
    ///   way; this only decides whether anyone hears about it. The default **stops the process in
    ///   debug builds and stays silent in release** — a shipped app must never die over
    ///   measurement, and a violation nobody notices during development is worth nothing.
    public init(onViolation: @escaping @Sendable (GA4Dialect.Violation) -> Void = Self.crashInDebug) {
        self.onViolation = onViolation
    }

    public func track(_ event: any AnalyticsEvent) {
        if let violation = GA4Dialect.validate(event) {
            onViolation(violation)
            return
        }
        FirebaseAnalytics.Analytics.logEvent(event.name, parameters: Self.encode(event.parameters))
    }

    public func setUserProperty(_ property: any AnalyticsUserProperty) {
        if let violation = GA4Dialect.validate(property) {
            onViolation(violation)
            return
        }
        FirebaseAnalytics.Analytics.setUserProperty(property.value, forName: property.name)
    }

    /// Default handling: stop the process in debug builds, let it pass in silence in release.
    ///
    /// **The silence is not swallowing the problem.** GA4 would have discarded the payload anyway,
    /// so not sending it loses nothing, and the debug trap means every violation is met head-on
    /// long before the build that ships.
    public static let crashInDebug: @Sendable (GA4Dialect.Violation) -> Void = { violation in
        #if DEBUG
        preconditionFailure("Analytics payload breaks a GA4 rule: \(violation.localizedDescription)")
        #endif
    }

    /// Converts parameter values into the two kinds Firebase carries: strings and numbers.
    ///
    /// Every case of ``AnalyticsCore/AnalyticsValue`` has a representation here, so nothing is
    /// lost in the crossing. Only booleans change shape: they go as `0` and `1` rather than as
    /// `"true"` and `"false"`, because GA4 can sum and average a number, while the two strings
    /// would only add values to a dimension and buy nothing.
    static func encode(_ parameters: [String: AnalyticsValue]) -> [String: Any] {
        parameters.mapValues { value in
            switch value {
            case let .text(text): return text as Any
            case let .count(count): return count as Any
            case let .number(number): return number as Any
            case let .flag(flag): return (flag ? 1 : 0) as Any
            }
        }
    }
}
