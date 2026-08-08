import AnalyticsCore
import Foundation

/// GA4（Firebase Analytics）が受け取れる形かどうかの検査。
///
/// GA4 は制約を破った送信を**黙って捨てる**。SDK は成功を返し、アプリからは何も起きていない
/// ように見えるので、ダッシュボードに数字が出ないことでしか気づけない。しかも
/// 「まだ誰も使っていない」と読めてしまうので、気づかないまま出荷される。
///
/// だから送る前に確かめる。制約は Firebase の公開仕様に基づく。
public enum GA4Dialect {

    /// 破った制約。
    public enum Violation: Error, Sendable, Equatable, LocalizedError {

        /// 名前が長すぎる（イベント名・パラメータ名とも 40 文字まで）。
        case nameTooLong(String, limit: Int)

        /// 名前に使えない文字が入っている（英数字と `_` のみ）。
        case nameHasInvalidCharacters(String)

        /// 名前が英字で始まっていない。
        case nameDoesNotStartWithLetter(String)

        /// Firebase が予約している接頭辞（`firebase_` / `google_` / `ga_`）。
        case reservedPrefix(String)

        /// Firebase が予約しているイベント名。
        case reservedName(String)

        /// パラメータが多すぎる（1 イベントにつき 25 個まで）。
        case tooManyParameters(String, count: Int)

        /// 文字列の値が長すぎる（100 文字まで）。
        case valueTooLong(key: String, length: Int)

        public var errorDescription: String? {
            switch self {
            case let .nameTooLong(name, limit):
                return "\(name) は \(limit) 文字を超えている"
            case let .nameHasInvalidCharacters(name):
                return "\(name) に使えない文字がある（英数字と _ のみ）"
            case let .nameDoesNotStartWithLetter(name):
                return "\(name) が英字で始まっていない"
            case let .reservedPrefix(name):
                return "\(name) は Firebase の予約接頭辞を使っている"
            case let .reservedName(name):
                return "\(name) は Firebase の予約イベント名"
            case let .tooManyParameters(name, count):
                return "\(name) のパラメータが \(count) 個ある（上限 25）"
            case let .valueTooLong(key, length):
                return "\(key) の値が \(length) 文字ある（上限 100）"
            }
        }
    }

    /// イベント名の上限。
    public static let nameLimit = 40
    /// 1 イベントに載せられるパラメータの数。
    public static let parameterLimit = 25
    /// 文字列の値の上限。
    public static let valueLimit = 100

    /// 使えない接頭辞。
    public static let reservedPrefixes = ["firebase_", "google_", "ga_"]

    /// 予約されているイベント名。カスタムイベントに使うと捨てられる。
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

    /// 送れる形かどうか。問題があれば最初の 1 つを返す。
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

    /// 属性が送れる形かどうか。
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
