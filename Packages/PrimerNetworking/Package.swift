// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrimerNetworking",
	platforms: [.iOS(.v13)],
	products: [
        .library(name: "PrimerNetworking", targets: ["PrimerNetworking"]),
    ],
    dependencies: [.package(path: "../PrimerFoundation")],
    targets: [
        .target(
            name: "PrimerNetworking",
            dependencies: [.product(name: "PrimerFoundation", package: "PrimerFoundation")]
        )
	]
)
