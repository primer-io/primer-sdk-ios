//
//  VersionUtilsTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class VersionUtilsTests: XCTestCase {

    override func tearDown() {
        Primer.shared.integrationOptions = nil
    }

    func test_releaseVersionNumber() throws {
        XCTAssertEqual(VersionUtils.releaseVersionNumber, PrimerSDKVersion)
    }

    func test_reactNativeVersion() throws {
        Primer.shared.integrationOptions = PrimerIntegrationOptions(reactNativeVersion: "1.0.0")
        XCTAssertEqual(VersionUtils.releaseVersionNumber, "1.0.0")
    }
}
