// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// DO NOT ADD DEPENDENCIES
let package = Package(
    name: "PrimerFoundation",
    platforms: [.iOS(.v13)],
    products: [.library(name: "PrimerFoundation", targets: ["PrimerFoundation"]),],
    targets: [
        .target(name: "PrimerFoundation"),
        .testTarget(name: "PrimerFoundationTests",dependencies: ["PrimerFoundation"]),
    ]
)
