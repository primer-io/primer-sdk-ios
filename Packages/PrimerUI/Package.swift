// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrimerUI",
	platforms: [.iOS(.v13)],
    products: [.library(name: "PrimerUI", targets: ["PrimerUI"])],
    dependencies: [.package(path: "../PrimerFoundation")],
    targets: [.target(
        name: "PrimerUI",
        dependencies: [.product(name: "PrimerFoundation", package: "PrimerFoundation")]
    )]
)
