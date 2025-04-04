//
//  ACHAdditionalInfoTests.swift
//
//
//  Created by Stefan Vrancianu on 05.08.2024.
//

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
