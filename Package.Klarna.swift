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
    dependencies: [
        .package(url: "https://github.com/primer-io/primer-klarna-sdk-ios", from: "1.4.0"),
    ],
    targets: [
        packageTarget(name: "PrimerFoundation"),
        packageTarget(name: "PrimerStepResolver", dependencies: ["PrimerFoundation"]),
        packageTarget(name: "PrimerBDCEngine", dependencies: ["PrimerFoundation", "PrimerStepResolver"]),
        packageTarget(name: "PrimerBDCCore", dependencies: ["PrimerBDCEngine", "PrimerFoundation", "PrimerStepResolver"]),
        packageTarget(name: "PrimerCore", dependencies: ["PrimerFoundation"]),
        .target(
            name: "PrimerSDK",
            dependencies: [
                .product(name: "PrimerKlarnaSDK", package: "primer-klarna-sdk-ios"),
                "PrimerBDCCore",
                "PrimerBDCEngine",
                "PrimerFoundation",
                "PrimerStepResolver",
                "PrimerCore"
            ],
            path: "Sources/PrimerSDK",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "Tests",
            dependencies: [
                .product(name: "PrimerKlarnaSDK", package: "primer-klarna-sdk-ios"),
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/",
            sources: [
                "Klarna/",
                "Utilities/"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)

private func packageTarget(name: String, dependencies: [Target.Dependency] = []) -> Target {
    .target(name: name, dependencies: dependencies, path: "Modules/\(name)/Sources")
}

private func packageTestTarget(name: String, dependencies: [Target.Dependency]) -> Target {
    .testTarget(name: "\(name)Tests", dependencies: dependencies, path: "Modules/\(name)/Tests/\(name)Tests")
}
