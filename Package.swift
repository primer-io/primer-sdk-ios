// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "PrimerSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS("16.1")
    ],
    products: [
        .library(
            name: "PrimerSDK",
            targets: ["PrimerSDK"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/primer-io/primer-sdk-3ds-ios", from: "2.4.4"),
		.package(path: "/Users/henrycooper/partners-tech-poc/apps/ios/PrimerNetworking"),
        .package(path: "/Users/henrycooper/partners-tech-poc/apps/ios/PrimerUI"),
        .package(path: "/Users/henrycooper/partners-tech-poc/apps/ios/PrimerBDCCore"),
        .package(path: "/Users/henrycooper/partners-tech-poc/apps/ios/PrimerFoundation")
    ],
    targets: [
        .target(
            name: "PrimerSDK",
            dependencies: [
                .product(name: "Primer3DS", package: "primer-sdk-3ds-ios"),
				.product(name: "PrimerNetworking", package: "PrimerNetworking"),
                .product(name: "PrimerUI", package: "PrimerUI"),
                .product(name: "PrimerBDCCore", package: "PrimerBDCCore"),
                .product(name: "PrimerFoundation", package: "PrimerFoundation"),
            ],
            path: "Sources/PrimerSDK",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "Debug_App",
            dependencies: [
                .byName(name: "PrimerSDK")
            ],
            path: "Debug App/Sources/",
            sources: [
                "Utilities/SecretsManager.swift",
                "Utilities/AppLinkConfigProvider.swift",
                "Model/TestSettings.swift",
                "Model/TestSettings+PrimerSettings.swift"
            ]
        ),
        .testTarget(
            name: "Tests",
            dependencies: [
                .product(name: "Primer3DS", package: "primer-sdk-3ds-ios"),
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/",
            sources: [
                "3DS/",
                "Utilities/",
                "Primer/"
            ]
        ),
        .testTarget(
            name: "DebugAppTests",
            dependencies: [
                .byName(name: "PrimerSDK"),
                .byName(name: "Debug_App")
            ],
            path: "Debug App/Tests",
            resources: [
                .process("Resources"),
                .copy("DebugAppTestPlan.xctestplan"),
                .copy("UnitTestsTestPlan.xctestplan"),
                .copy("Debug App Tests-Info.plist")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
