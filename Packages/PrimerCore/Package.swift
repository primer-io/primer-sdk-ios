// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrimerCore",
    platforms: [.iOS(.v13)],
    products: [.library(name: "PrimerCore", targets: ["PrimerCore"])],
    dependencies: [
        .package(url: "https://github.com/primer-io/primer-sdk-3ds-ios", from: "2.7.0"),
        .package(path: "../PrimerFoundation")
    ],
    targets: [
        .target(
            name: "PrimerCore",
            dependencies: [
                .product(name: "Primer3DS", package: "primer-sdk-3ds-ios"),
                .product(name: "PrimerFoundation", package: "PrimerFoundation")
            ]
        )
    ]
)
