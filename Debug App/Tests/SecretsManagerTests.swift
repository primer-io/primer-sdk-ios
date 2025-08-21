//
//  SecretsManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import Debug_App

final class SecretsManagerTests: XCTestCase {

    func testLoadFileAndGetSecret() throws {
        let bundle = Bundle(for: type(of: self))
        guard let nestedBundleURL = bundle.url(forResource: "PrimerSDK_DebugAppTests", withExtension: "bundle"),
              let resourceBundle = Bundle(url: nestedBundleURL) else {
            return XCTFail("Could not find PrimerSDK_DebugAppTests.bundle")
        }

        let manager = SecretsManager(bundle: resourceBundle)
        XCTAssertEqual(manager.properties.count, 1)

        let stripePublishableKey = manager.value(forKey: .stripePublishableKey)
        XCTAssertEqual(stripePublishableKey, "pk_test_123")
    }
}
