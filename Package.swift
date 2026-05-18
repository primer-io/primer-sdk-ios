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
        .target(
            name: "PrimerSDK",
            dependencies: [
                .product(name: "Primer3DS", package: "primer-sdk-3ds-ios"),
                "PrimerBDCCore",
                "PrimerBDCEngine",
                "PrimerFoundation",
                "PrimerStepResolver"
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
        packageTestTarget(name: "PrimerBDCCore", dependencies: ["PrimerBDCCore", "PrimerFoundation", "PrimerStepResolver", "PrimerBDCEngine"]),
        packageTestTarget(name: "PrimerBDCEngine", dependencies: ["PrimerBDCEngine"]),
        packageTestTarget(name: "PrimerFoundation", dependencies: ["PrimerFoundation"]),
        packageTestTarget(name: "PrimerStepResolver", dependencies: ["PrimerStepResolver"]),
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

private func packageTarget(name: String, dependencies: [Target.Dependency] = []) -> Target {
    .target(name: name, dependencies: dependencies, path: "Packages/\(name)/Sources")
}

private func packageTestTarget(name: String, dependencies: [Target.Dependency]) -> Target {
    .testTarget(name: "\(name)Tests", dependencies: dependencies, path: "Packages/\(name)/Tests/\(name)Tests")
}
//
//  klarna-addition.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

let packageDep: Package.Dependency = .package(
    url: "https://github.com/primer-io/primer-klarna-sdk-ios",
    from: "1.3.1"
)

let targetDep: Target.Dependency = .product(
    name: "PrimerKlarnaSDK",
    package: "primer-klarna-sdk-ios"
)

package.dependencies.append(packageDep)

let targets = package.targets
let sdk = targets.first { $0.name == "PrimerSDK" }
let tests = targets.first { $0.name == "Tests" }

sdk?.dependencies.append(targetDep)
tests?.dependencies.append(targetDep)
tests?.sources?.append("Klarna/")
