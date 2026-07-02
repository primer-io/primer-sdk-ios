// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "PrimerSDK",
    defaultLocalization: "en",
    platforms: [.iOS("13.1")],
    products: [.library(name: "PrimerSDK", targets: ["PrimerSDK"])],
    dependencies: [.package(url: "https://github.com/primer-io/primer-sdk-3ds-ios", from: "2.7.0")],
    targets: packageTargets,
    swiftLanguageVersions: [.v5]
)

private var packageTargets: [Target] {
    [
        .target(name: "PrimerSDK", dependencies: primerSDKDependencies, path: "Sources/PrimerSDK"),
        
        target(name: "PrimerFoundation"),
        target(name: "PrimerStepResolver", dependencies: ["PrimerFoundation"]),
        target(name: "PrimerBDCEngine", dependencies: ["PrimerFoundation", "PrimerStepResolver"]),
        target(name: "PrimerBDCCore", dependencies: ["PrimerBDCEngine", "PrimerFoundation", "PrimerStepResolver"]),
        target(name: "PrimerCore", dependencies: ["PrimerFoundation", "PrimerResources"]),
        target(name: "PrimerNetworking", dependencies: ["PrimerFoundation"]),
        target(name: "PrimerResources", resources: [.process("PrimerResources/Resources")]),
        target(name: "PrimerUI"),
        
        sdkTestsTarget,
        
        testTarget(name: "PrimerBDCCore", dependencies: ["PrimerBDCCore", "PrimerFoundation", "PrimerStepResolver", "PrimerBDCEngine"]),
        testTarget(name: "PrimerBDCEngine", dependencies: ["PrimerBDCEngine"]),
        testTarget(name: "PrimerFoundation", dependencies: ["PrimerFoundation"]),
        testTarget(name: "PrimerStepResolver", dependencies: ["PrimerStepResolver"]),
    ]
}

private var primerSDKDependencies: [Target.Dependency] {
    [
        .product(name: "Primer3DS", package: "primer-sdk-3ds-ios"),
        "PrimerBDCCore",
        "PrimerBDCEngine",
        "PrimerFoundation",
        "PrimerStepResolver",
        "PrimerCore",
        "PrimerNetworking",
        "PrimerResources",
        "PrimerUI"
    ]
}

private var sdkTestsTarget: Target {
    .target(
        name: "Tests",
        dependencies: [.product(name: "Primer3DS", package: "primer-sdk-3ds-ios"), .byName(name: "PrimerSDK")],
        path: "Tests/",
        sources: ["3DS/", "Utilities/"]
    )
}

private func target(name: String, dependencies: [Target.Dependency] = [], resources: [Resource] = []) -> Target {
    .target(name: name, dependencies: dependencies, path: "Modules/\(name)/Sources", resources: resources)
}

private func testTarget(name: String, dependencies: [Target.Dependency]) -> Target {
    .testTarget(name: "\(name)Tests", dependencies: dependencies, path: "Modules/\(name)/Tests/\(name)Tests")
}
