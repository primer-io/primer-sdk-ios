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
        .package(url: "https://github.com/primer-io/primer-sdk-3ds-ios", from: "2.7.0")
    ],
    targets: [
        packageTarget(name: "PrimerFoundation"),
        packageTarget(name: "PrimerStepResolver", dependencies: ["PrimerFoundation"]),
        packageTarget(name: "PrimerBDCEngine", dependencies: ["PrimerFoundation", "PrimerStepResolver"]),
        packageTarget(name: "PrimerBDCCore", dependencies: ["PrimerBDCEngine", "PrimerFoundation", "PrimerStepResolver"]),
        packageTarget(name: "PrimerCore", dependencies: ["PrimerFoundation"]),
        packageTarget(name: "PrimerNetworking", dependencies: ["PrimerFoundation"]),
        packageTarget(name: "PrimerResources", resources: [.process("PrimerResources/Resources")]),
        .target(
            name: "PrimerSDK",
            dependencies: [
                .product(name: "Primer3DS", package: "primer-sdk-3ds-ios"),
                "PrimerBDCCore",
                "PrimerBDCEngine",
                "PrimerFoundation",
                "PrimerStepResolver",
                "PrimerCore",
                "PrimerNetworking",
                "PrimerResources"
            ],
            path: "Sources/PrimerSDK",
            resources: [
                .process("Resources")
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
                "Utilities/"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)

private func packageTarget(name: String, dependencies: [Target.Dependency] = [], resources: [Resource] = []) -> Target {
    .target(name: name, dependencies: dependencies, path: "Modules/\(name)/Sources", resources: resources)
}

private func packageTestTarget(name: String, dependencies: [Target.Dependency]) -> Target {
    .testTarget(name: "\(name)Tests", dependencies: dependencies, path: "Modules/\(name)/Tests/\(name)Tests")
}
