// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrimerBDCCore",
    platforms: [.iOS(.v13)],
    products: [.library(name: "PrimerBDCCore", targets: ["PrimerBDCCore"]),],
    dependencies: [
        .package(path: "../PrimerBDCEngine"),
        .package(path: "../PrimerFoundation"),
        .package(path: "../PrimerStepResolver")
    ],
    targets: [.target(
        name: "PrimerBDCCore",
        dependencies: [
            .product(name: "PrimerBDCEngine", package: "PrimerBDCEngine"),
            .product(name: "PrimerFoundation", package: "PrimerFoundation"),
            .product(name: "PrimerStepResolver", package: "PrimerStepResolver")
        ])
    ]
)
