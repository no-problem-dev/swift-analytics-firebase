import AnalyticsCore
import FirebaseAnalytics
import Foundation

/// ``AnalyticsCore/AnalyticsClient`` の Firebase Analytics 実装。
///
/// **vendor を知っているのはこの型だけ。** 送信は fire-and-forget で、SDK 側がバッチと再送を
/// 持っているので、こちらでリトライもエラー処理もしない（計測のためにアプリを止めない）。
///
/// ## 使い方
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
/// ## 送る前に確かめていること
///
/// GA4 の制約を破った送信は**成功したように見えて捨てられる**（ダッシュボードに出ないことでしか
/// 気づけない）。名前と値の検査は ``GA4Dialect`` が持っていて、開発中は破った時点で分かるようにする。
public struct FirebaseAnalyticsClient: AnalyticsClient {

    private let onViolation: @Sendable (GA4Dialect.Violation) -> Void

    /// - Parameter onViolation: GA4 の制約を破った送信を見つけたときの扱い。
    ///   既定は **DEBUG では停止、RELEASE では送らずに握る**。
    ///   出荷後に計測のために落とすことはしないが、開発中は気づけないと意味が無い。
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

    /// 既定の扱い。DEBUG では止め、RELEASE では送らずに見送る。
    ///
    /// **握りつぶしではない。** 送っても捨てられる値なので送らないだけで、
    /// 開発中は必ず止まるので、出荷までに気づける経路が残っている。
    public static let crashInDebug: @Sendable (GA4Dialect.Violation) -> Void = { violation in
        #if DEBUG
        preconditionFailure("GA4 の制約に反する計測: \(violation.localizedDescription)")
        #endif
    }

    /// ``AnalyticsCore/AnalyticsValue`` を GA4 が受け取れる形に落とす。
    ///
    /// 真偽は `0` / `1` の数値にする —— GA4 では真偽をそのまま送るより数値のほうが集計しやすく、
    /// 文字列の `"true"` は値の集合が増えるだけで何も得しない。
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
