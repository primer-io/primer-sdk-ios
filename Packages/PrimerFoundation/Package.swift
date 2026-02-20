// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// DO NOT ADD DEPENDENCIES
let package = Package(
    name: "PrimerFoundation",
    products: [.library(name: "PrimerFoundation", targets: ["PrimerFoundation"])],
    targets: [.target(name: "PrimerFoundation")]
)
