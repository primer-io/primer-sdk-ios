// swift-tools-version:5.3

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
            targets: ["PrimerSDK"]
        )
    ],
    targets: [
        .target(
            name: "PrimerSDK",
            path: "Sources/PrimerSDK",
            resources: [
                .process("Resources"),
                .copy("Classes/Third Party/PromiseKit/LICENSE")
            ]
        ),
        .testTarget(
            name: "PrimerSDKTests",
            dependencies: [
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/Unit Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
