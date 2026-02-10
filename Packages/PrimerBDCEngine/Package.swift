// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrimerBDCEngine",
    platforms: [.iOS(.v13)],
    products: [.library(name: "PrimerBDCEngine",targets: ["PrimerBDCEngine"])],
    dependencies: [.package(path: "../PrimerFoundation"), .package(path: "../PrimerStepResolver")],
    targets: [
        .target(
            name: "PrimerBDCEngine",
            dependencies: [
                .product(name: "PrimerFoundation", package: "PrimerFoundation"),
                .product(name: "PrimerStepResolver", package: "PrimerStepResolver")
            ]
        ),
    ]
)
