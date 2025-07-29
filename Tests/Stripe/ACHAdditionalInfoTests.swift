//
//  ACHAdditionalInfoTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import XCTest
@testable import PrimerSDK

class ACHAdditionalInfoTests: XCTestCase {

    func test_ACHBankAccountCollector_additionalInfo_initialization() {
        let mockViewController = UIViewController()
        let additionalInfo = ACHBankAccountCollectorAdditionalInfo(collectorViewController: mockViewController)

        XCTAssertEqual(additionalInfo.collectorViewController, mockViewController, "collectorViewController should be set correctly")
    }

    func test_ACHBankAccountCollector_additionalInfo_decoderInitialization() {
        do {
            let decoder = JSONDecoder()
            let data = Data()
            _ = try decoder.decode(ACHBankAccountCollectorAdditionalInfo.self, from: data)
            XCTFail("init(from:) should throw an error")
        } catch {
            XCTAssert(true, "init(from:) should throw an error")
        }
    }

    func test_ACHMandateAdditionalInfo_initialization() {
        let additionalInfo = ACHMandateAdditionalInfo()
        XCTAssertNotNil(additionalInfo, "ACHMandateAdditionalInfo should initialize correctly")
    }
}
