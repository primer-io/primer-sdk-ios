// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrimerCore",
    platforms: [.iOS(.v13)],
    products: [.library(name: "PrimerCore", targets: ["PrimerCore"])],
    dependencies: [
        .package(path: "../PrimerFoundation")
    ],
    targets: [
        .target(
            name: "PrimerCore",
            dependencies: [
                .product(name: "PrimerFoundation", package: "PrimerFoundation")
            ]
        )
    ]
)
