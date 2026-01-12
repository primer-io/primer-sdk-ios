//
//  PrimerInternalTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class PrimerInternalTests: XCTestCase {

    override func tearDown() {
        // Reset sdkInitTimestamp after each test
        PrimerInternal.shared.sdkInitTimestamp = nil
    }

    // MARK: - sdkInitTimestamp Tests

    func testConfigure_setsSdkInitTimestamp() {
        // Given
        XCTAssertNil(PrimerInternal.shared.sdkInitTimestamp)

        // When
        PrimerInternal.shared.configure(settings: nil)

        // Then
        XCTAssertNotNil(PrimerInternal.shared.sdkInitTimestamp)
    }

    func testConfigure_setsTimestampToCurrentTime() {
        // Given
        let beforeTimestamp = Date().millisecondsSince1970

        // When
        PrimerInternal.shared.configure(settings: nil)

        // Then
        let afterTimestamp = Date().millisecondsSince1970
        guard let sdkInitTimestamp = PrimerInternal.shared.sdkInitTimestamp else {
            XCTFail("sdkInitTimestamp should not be nil")
            return
        }

        XCTAssertGreaterThanOrEqual(sdkInitTimestamp, beforeTimestamp)
        XCTAssertLessThanOrEqual(sdkInitTimestamp, afterTimestamp)
    }

    func testConfigure_calledMultipleTimes_updatesTimestamp() {
        // Given
        PrimerInternal.shared.configure(settings: nil)
        let firstTimestamp = PrimerInternal.shared.sdkInitTimestamp

        // Small delay to ensure different timestamp
        Thread.sleep(forTimeInterval: 0.01)

        // When
        PrimerInternal.shared.configure(settings: nil)
        let secondTimestamp = PrimerInternal.shared.sdkInitTimestamp

        // Then
        XCTAssertNotNil(firstTimestamp)
        XCTAssertNotNil(secondTimestamp)
        XCTAssertGreaterThanOrEqual(secondTimestamp!, firstTimestamp!)
    }
}
