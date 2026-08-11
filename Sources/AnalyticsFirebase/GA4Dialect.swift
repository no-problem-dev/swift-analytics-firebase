import AnalyticsCore
import Foundation

/// Checks whether an event or user property is in a shape GA4 will actually accept.
///
/// GA4 discards a payload that breaks its limits **without reporting an error**. The SDK call
/// succeeds, nothing surfaces in the app, and the only symptom is a number that never appears on
/// the dashboard — which reads as "nobody has used this yet", so it ships unnoticed.
///
/// So the shape is checked before anything is handed to Firebase, against its published limits:
///
/// | Rule | Limit |
/// |---|---|
/// | Name length — event, parameter and user property names alike | 40 characters |
/// | Characters allowed in a name | ASCII letters, digits and `_`, first character a letter |
/// | Reserved prefixes, refused on every kind of name | `firebase_`, `google_`, `ga_` |
/// | Firebase's own event names, refused as event names only | ``reservedNames`` |
/// | Parameters on one event | 25 |
/// | String value length | 100 characters |
///
/// Only string values are measured; numbers are not.
///
/// **Nothing is truncated or rewritten here.** Validation reports the first rule broken and stops,
/// and ``FirebaseAnalyticsClient`` drops the whole event or property rather than send a partial
/// one. GA4 caps user property names and values more tightly than it caps event parameters, so a
/// long property can clear this check and still not survive on Google's side.
public enum GA4Dialect {

    /// A GA4 rule an event or user property breaks, carrying the name at fault and what was measured.
    public enum Violation: Error, Sendable, Equatable, LocalizedError {

        /// A name is longer than 40 characters — the same limit for events, parameters and properties.
        case nameTooLong(String, limit: Int)

        /// A name contains something other than ASCII letters, digits and `_`.
        case nameHasInvalidCharacters(String)

        /// A name is empty, or starts with anything but an ASCII letter — a digit, `_`, or Japanese.
        case nameDoesNotStartWithLetter(String)

        /// A name begins with a prefix Firebase keeps for itself. Carries the prefix, not the name.
        case reservedPrefix(String)

        /// An event name collides with one Firebase logs on its own. Parameter names are exempt.
        case reservedName(String)

        /// An event carries more than the 25 parameters GA4 accepts.
        case tooManyParameters(String, count: Int)

        /// A string value is longer than 100 characters. Numbers are never measured.
        case valueTooLong(key: String, length: Int)

        public var errorDescription: String? {
            switch self {
            case let .nameTooLong(name, limit):
                return "\(name) is longer than \(limit) characters"
            case let .nameHasInvalidCharacters(name):
                return "\(name) contains something other than ASCII letters, digits and _"
            case let .nameDoesNotStartWithLetter(name):
                return "\(name) does not start with an ASCII letter"
            case let .reservedPrefix(prefix):
                return "\(prefix) is a prefix Firebase reserves"
            case let .reservedName(name):
                return "\(name) is an event name Firebase reserves"
            case let .tooManyParameters(name, count):
                return "\(name) carries \(count) parameters (limit \(GA4Dialect.parameterLimit))"
            case let .valueTooLong(key, length):
                return "\(key) has a value of \(length) characters (limit \(GA4Dialect.valueLimit))"
            }
        }
    }

    /// Longest name GA4 accepts, in characters. Applies to events, parameters and user properties.
    public static let nameLimit = 40
    /// Most parameters GA4 will carry on one event. An event with more is refused whole, not trimmed.
    public static let parameterLimit = 25
    /// Longest string value GA4 accepts, in characters. Numeric values are not measured against it.
    public static let valueLimit = 100

    /// Prefixes Firebase keeps for itself, refused on event, parameter and user property names alike.
    public static let reservedPrefixes = ["firebase_", "google_", "ga_"]

    /// Event names Firebase logs on its own; reusing one for a custom event means it is discarded.
    ///
    /// These stay usable as parameter and user property names — only the event name is refused.
    public static let reservedNames: Set<String> = [
        "ad_activeview", "ad_click", "ad_exposure", "ad_impression", "ad_query", "ad_reward",
        "adunit_exposure", "app_background", "app_clear_data", "app_exception", "app_remove",
        "app_store_refund", "app_store_subscription_cancel", "app_store_subscription_convert",
        "app_store_subscription_renew", "app_update", "app_upgrade", "dynamic_link_app_open",
        "dynamic_link_app_update", "dynamic_link_first_open", "error", "firebase_campaign",
        "first_open", "first_visit", "in_app_purchase", "notification_dismiss",
        "notification_foreground", "notification_open", "notification_receive", "os_update",
        "session_start", "session_start_with_rollout", "user_engagement"
    ]

    /// Returns the first GA4 rule the event breaks, or nothing when it is safe to send.
    ///
    /// Checked in that order: the event name, then how many parameters there are, then each
    /// parameter's name and — for string values only — its length. Checking stops at the first
    /// failure, so an event with several problems surfaces them one at a time.
    public static func validate(_ event: any AnalyticsEvent) -> Violation? {
        if let violation = validateName(event.name, allowReservedNames: false) {
            return violation
        }
        if event.parameters.count > parameterLimit {
            return .tooManyParameters(event.name, count: event.parameters.count)
        }
        for (key, value) in event.parameters {
            if let violation = validateName(key, allowReservedNames: true) {
                return violation
            }
            if case let .text(text) = value, text.count > valueLimit {
                return .valueTooLong(key: key, length: text.count)
            }
        }
        return nil
    }

    /// Returns the first GA4 rule the user property breaks, or nothing when it is safe to send.
    ///
    /// The name is held to the same limits as a parameter name, so Firebase's reserved event names
    /// pass — a property called `error` is fine — while the reserved prefixes are still refused.
    public static func validate(_ property: any AnalyticsUserProperty) -> Violation? {
        if let violation = validateName(property.name, allowReservedNames: true) {
            return violation
        }
        if property.value.count > valueLimit {
            return .valueTooLong(key: property.name, length: property.value.count)
        }
        return nil
    }

    static func validateName(_ name: String, allowReservedNames: Bool) -> Violation? {
        guard name.count <= nameLimit else { return .nameTooLong(name, limit: nameLimit) }
        guard let first = name.first, first.isLetter, first.isASCII else {
            return .nameDoesNotStartWithLetter(name)
        }
        guard name.allSatisfy({ ($0.isLetter || $0.isNumber || $0 == "_") && $0.isASCII }) else {
            return .nameHasInvalidCharacters(name)
        }
        if let prefix = reservedPrefixes.first(where: { name.hasPrefix($0) }) {
            return .reservedPrefix(prefix)
        }
        if !allowReservedNames, reservedNames.contains(name) {
            return .reservedName(name)
        }
        return nil
    }
}
