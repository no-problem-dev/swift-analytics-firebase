// swift-tools-version: 6.2
import PackageDescription

/// The Firebase Analytics implementation of `swift-analytics`.
///
/// **It lives apart from the core because SwiftPM resolves dependencies per package.** Bundling the
/// adapter into `swift-analytics` would pull the Firebase SDK into consumers that only use the
/// vocabulary — domain layers, previews, tests. Splitting targets does not split resolution.
///
/// Isolating a dependency is the only reason this is a separate repository. Nothing else earns one.
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
        .package(url: "https://github.com/no-problem-dev/swift-analytics.git", .upToNextMinor(from: "0.1.0")),
        // **Do not add `FirebaseAnalyticsIdentitySupport`.** In firebase-ios-sdk 12.x,
        // `FirebaseAnalytics` does not collect IDFA by default; adding Identity is what turns it on.
        // Its absence is therefore the specification, and must survive any tidying of dependencies.
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
