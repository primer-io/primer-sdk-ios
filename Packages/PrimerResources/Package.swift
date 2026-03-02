// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrimerResources",
    defaultLocalization: "en",
	platforms: [.iOS(.v13)],
    products: [.library(name: "PrimerResources", targets: ["PrimerResources"])],
    targets: [.target(name: "PrimerResources", resources: [.process("Resources")])]
)
