// swift-tools-version: 6.2
import PackageDescription

/// `swift-analytics` の Firebase Analytics 実装。
///
/// **本体から切り離してあるのは、SwiftPM が依存をパッケージ単位で解決するから。**
/// アダプタを `swift-analytics` に同居させると、語彙しか使わない消費者（ドメイン層・
/// プレビュー・テスト）にも Firebase の SDK が降ってくる。ターゲットを分けても解決は分けられない。
///
/// リポジトリを分けているのは「依存を隔離したい」から。それ以外の理由では分けない。
let package = Package(
    name: "swift-analytics-firebase",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "AnalyticsFirebase", targets: ["AnalyticsFirebase"])
    ],
    dependencies: [
        .package(url: "https://github.com/no-problem-dev/swift-analytics.git", from: "0.1.0"),
        // **`FirebaseAnalyticsIdentitySupport` を足さない。** firebase-ios-sdk 12.x では
        // `FirebaseAnalytics` が既定で IDFA を集めず、Identity を足したときだけ集める。
        // つまり「足さないこと」が仕様であり、依存を整理するときに消してはならない。
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.0.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0")
    ],
    targets: [
        .target(
            name: "AnalyticsFirebase",
            dependencies: [
                .product(name: "AnalyticsCore", package: "swift-analytics"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ]
        ),
        .testTarget(
            name: "AnalyticsFirebaseTests",
            dependencies: [
                "AnalyticsFirebase",
                .product(name: "AnalyticsCore", package: "swift-analytics")
            ]
        )
    ]
)
