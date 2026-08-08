import AnalyticsCore
import Testing
@testable import AnalyticsFirebase

/// GA4 が黙って捨てる形を、送る前に落とせること。
@Suite("GA4 の制約")
struct GA4DialectTests {

    @Test("ふつうの名前は通る")
    func acceptsValidNames() {
        #expect(GA4Dialect.validate(Event(name: "paywall_shown")) == nil)
    }

    @Test("40 文字を超える名前は落ちる")
    func rejectsLongNames() {
        let name = String(repeating: "a", count: 41)
        #expect(GA4Dialect.validate(Event(name: name)) == .nameTooLong(name, limit: 40))
    }

    @Test("英字で始まらない名前は落ちる")
    func rejectsNamesNotStartingWithLetter() {
        #expect(GA4Dialect.validate(Event(name: "1st_open")) == .nameDoesNotStartWithLetter("1st_open"))
        #expect(GA4Dialect.validate(Event(name: "_open")) == .nameDoesNotStartWithLetter("_open"))
    }

    @Test("英数字と _ 以外は落ちる")
    func rejectsInvalidCharacters() {
        #expect(GA4Dialect.validate(Event(name: "paywall-shown")) == .nameHasInvalidCharacters("paywall-shown"))
        // 日本語の名前は通らない。**送信は成功して見えるので、ここで止めないと気づけない**
        #expect(GA4Dialect.validate(Event(name: "ペイウォール")) != nil)
    }

    @Test("予約接頭辞は落ちる")
    func rejectsReservedPrefixes() {
        #expect(GA4Dialect.validate(Event(name: "firebase_ready")) == .reservedPrefix("firebase_"))
        #expect(GA4Dialect.validate(Event(name: "ga_hit")) == .reservedPrefix("ga_"))
    }

    @Test("予約イベント名は落ちる")
    func rejectsReservedNames() {
        #expect(GA4Dialect.validate(Event(name: "first_open")) == .reservedName("first_open"))
        #expect(GA4Dialect.validate(Event(name: "session_start")) == .reservedName("session_start"))
    }

    @Test("予約名でもパラメータ名としては使える")
    func allowsReservedWordsAsParameterNames() {
        let event = Event(name: "custom", parameters: ["error": .count(1)])
        #expect(GA4Dialect.validate(event) == nil)
    }

    @Test("パラメータ 26 個は落ちる")
    func rejectsTooManyParameters() {
        let parameters = Dictionary(
            uniqueKeysWithValues: (0..<26).map { ("p\($0)", AnalyticsValue.count($0)) }
        )
        #expect(GA4Dialect.validate(Event(name: "custom", parameters: parameters)) == .tooManyParameters("custom", count: 26))
    }

    @Test("100 文字を超える値は落ちる")
    func rejectsLongValues() {
        let text = String(repeating: "x", count: 101)
        let event = Event(name: "custom", parameters: ["note": .text(text)])
        #expect(GA4Dialect.validate(event) == .valueTooLong(key: "note", length: 101))
    }

    @Test("属性も同じ制約で見る")
    func validatesUserProperties() {
        #expect(GA4Dialect.validate(Property(name: "plan", value: "free")) == nil)
        #expect(GA4Dialect.validate(Property(name: "firebase_plan", value: "free")) == .reservedPrefix("firebase_"))
    }
}

@Suite("GA4 への値の落とし方")
struct GA4EncodingTests {

    @Test("真偽は 0 / 1 の数値にする")
    func encodesBoolAsNumber() {
        let encoded = FirebaseAnalyticsClient.encode(["changed": .flag(true), "answered": .flag(false)])
        #expect(encoded["changed"] as? Int == 1)
        #expect(encoded["answered"] as? Int == 0)
    }

    @Test("文字列と数値はそのまま渡す")
    func passesThroughTextAndNumbers() {
        let encoded = FirebaseAnalyticsClient.encode(["source": .text("teaser"), "day": .count(3)])
        #expect(encoded["source"] as? String == "teaser")
        #expect(encoded["day"] as? Int == 3)
    }
}

// MARK: - テスト用の最小の準拠

private struct Event: AnalyticsEvent {
    let name: String
    var parameters: [String: AnalyticsValue] = [:]
    var kind: EventKind { .interaction }
    var dedup: DedupScope { .always }
}

private struct Property: AnalyticsUserProperty {
    let name: String
    let value: String
}
