//
//  VersionUtilsTests.swift
//  Debug App Tests
//
//  Created by Niall Quinn on 26/09/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

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
