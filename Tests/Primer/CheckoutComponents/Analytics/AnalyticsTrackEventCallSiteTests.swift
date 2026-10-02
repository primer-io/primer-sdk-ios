//
//  AnalyticsTrackEventCallSiteTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest

/// Contract S2: `trackEvent(` is the raw, untyped entry point. Every call site must go through
/// `AnalyticsFunnel`'s typed helpers, so this stays the only place that builds event payloads
/// by hand.
final class AnalyticsTrackEventCallSiteTests: XCTestCase {

    private static let allowedCallSites: Set<String> = [
        "Analytics/Domain/AnalyticsFunnel.swift",
        "Analytics/Domain/Interactors/DefaultAnalyticsInteractor.swift",
        "Analytics/Domain/Protocols/AnalyticsInteractorProtocol.swift",
        "Internal/Bridge/ComponentsAnalyticsLoggingBridge.swift"
    ]

    func test_trackEventCallSites_areRestrictedToTheAllowedList() throws {
        let root = try Self.checkoutComponentsRoot(from: #filePath)

        let offenders = try Self.swiftFiles(under: root).compactMap { file -> String? in
            let contents = try String(contentsOf: file, encoding: .utf8)
            guard contents.contains("trackEvent(") else { return nil }
            let relativePath = String(file.path.dropFirst(root.path.count + 1))
            return Self.allowedCallSites.contains(relativePath) ? nil : relativePath
        }

        XCTAssertTrue(
            offenders.isEmpty,
            "trackEvent( must only be called from AnalyticsFunnel, DefaultAnalyticsInteractor, " +
                "AnalyticsInteractorProtocol or ComponentsAnalyticsLoggingBridge. Found it in: " +
                offenders.sorted().joined(separator: ", ")
        )
    }

    /// Walks up from this test file until it finds the `CheckoutComponents` source root, so the
    /// guard survives the test file moving without hardcoding a relative depth.
    private static func checkoutComponentsRoot(from filePath: String) throws -> URL {
        var directory = URL(fileURLWithPath: filePath).deletingLastPathComponent()
        let fileManager = FileManager.default

        while true {
            let candidate = directory.appendingPathComponent("Sources/PrimerSDK/Classes/CheckoutComponents")
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: candidate.path, isDirectory: &isDirectory), isDirectory.boolValue {
                return candidate
            }
            let parent = directory.deletingLastPathComponent()
            guard parent.path != directory.path else {
                throw TestError.validationFailed(
                    "Could not locate Sources/PrimerSDK/Classes/CheckoutComponents from \(filePath)"
                )
            }
            directory = parent
        }
    }

    private static func swiftFiles(under root: URL) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw TestError.validationFailed("Could not enumerate \(root.path)")
        }
        return enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
    }
}
