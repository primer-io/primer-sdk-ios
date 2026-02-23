// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrimerStepResolver",
    platforms: [.iOS(.v13)],
    products: [.library(name: "PrimerStepResolver", targets: ["PrimerStepResolver"])],
    dependencies: [.package(path: "../PrimerFoundation")],
    targets: [.target(
        name: "PrimerStepResolver",
        dependencies: [.product(name: "PrimerFoundation", package: "PrimerFoundation")]
    )]
)
