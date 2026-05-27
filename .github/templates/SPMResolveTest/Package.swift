// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SPMTest",
    platforms: [.iOS(.v13)],
    dependencies: [.package(url: "__REPO_URL__", branch: "__BRANCH__")],
    targets: [
        .target(
            name: "SPMTest",
            dependencies: [.product(name: "PrimerSDK", package: "primer-sdk-ios")],
            path: "Sources/SPMTest"
        )
    ]
)
