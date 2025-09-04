// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "PrimerSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS("13.1")
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
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "Tests",
            dependencies: [
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/",
            sources: [
                "Primer/",
                "Utilities/"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
