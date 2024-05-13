// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "PrimerSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "PrimerSDK",
            targets: [
                "PrimerSDK",
                "__PrimerSDK_PromiseKit"
            ]
        )
    ],
    targets: [
        .target(
            name: "PrimerSDK",
            dependencies: [
                .target(name: "__PrimerSDK_PromiseKit")
            ],
            path: "Sources/PrimerSDK",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "__PrimerSDK_PromiseKit",
            path: "Sources/PromiseKit",
            resources: [
                .copy("LICENSE")
            ]
        ),
        .testTarget(
            name: "PrimerSDKTests",
            dependencies: [
                .byName(name: "PrimerSDK"),
                .byName(name: "__PrimerSDK_PromiseKit")
            ],
            path: "Tests/Unit Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
