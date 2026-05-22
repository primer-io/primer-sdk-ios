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
    dependencies: [.package(url: "https://github.com/primer-io/primer-nol-pay-sdk-ios", from: "1.0.2")],
    targets: [
        packageTarget(name: "PrimerFoundation"),
        packageTarget(name: "PrimerStepResolver", dependencies: ["PrimerFoundation"]),
        packageTarget(name: "PrimerBDCEngine", dependencies: ["PrimerFoundation", "PrimerStepResolver"]),
        packageTarget(name: "PrimerBDCCore", dependencies: ["PrimerBDCEngine", "PrimerFoundation", "PrimerStepResolver"]),
        packageTarget(name: "PrimerCore", dependencies: ["PrimerFoundation"]),
        .target(
            name: "PrimerSDK",
            dependencies: [
                .product(name: "PrimerNolPaySDK", package: "primer-nol-pay-sdk-ios"),
                "PrimerBDCCore",
                "PrimerBDCEngine",
                "PrimerFoundation",
                "PrimerStepResolver",
                "PrimerCore"
            ],
        ),
        .testTarget(
            name: "Tests",
            dependencies: [
                .product(name: "PrimerNolPaySDK", package: "primer-nol-pay-sdk-ios"),
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/",
            sources: [
                "NolPay/",
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
