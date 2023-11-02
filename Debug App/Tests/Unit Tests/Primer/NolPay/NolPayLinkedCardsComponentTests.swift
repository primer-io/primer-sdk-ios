//
//  NolPayLinkedCardsComponentTests.swift
//  Debug App Tests
//
//  Created by Boris on 4.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerNolPaySDK)
import XCTest
@testable import PrimerSDK
import PrimerNolPaySDK

class NolPayLinkedCardsComponentTests: XCTestCase {
    
    func testInitialization() {
        let component = NolPayLinkedCardsComponent(isDebug: true)
        XCTAssertNotNil(component)
    }

    func testGetLinkedCardsWithValidMobileNumber() {
        let component = NolPayLinkedCardsComponent(isDebug: true)
        let mockNolPay = MockPrimerNolPay(appId: "", isDebug: true, isSandbox: true, appSecretHandler: { sdkId, deviceId in
            return "appSecret"
        })
        
        let mockPhoneMetadataService = MockPhoneMetadataService()
        mockPhoneMetadataService.resultToReturn = .success((.valid, "+123", "1234567890"))
        component.phoneMetadataService = mockPhoneMetadataService
        component.nolPay = mockNolPay
        
        let expectation = self.expectation(description: "Wait for getLinkedCards to return")
        
        component.getLinkedCardsFor(mobileNumber: "1234567890") { result in
            switch result {
            case .success(let cards):
                XCTAssertNotNil(cards)
                XCTAssertEqual(cards.count, 1)
                XCTAssertEqual(cards.first?.cardNumber, "1234567890123456")
            case .failure(let error):
                XCTFail("Expected success, but got error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetLinkedCardsFor_WhenSDKNotAvailable() {
        let component = NolPayLinkedCardsComponent(isDebug: true)
        component.nolPay = nil // Setting nolPay to nil to simulate SDK unavailability
        
        let expectation = self.expectation(description: "Get Linked Cards For SDK Not Available")
        
        component.getLinkedCardsFor(mobileNumber: "+1234567890") { result in
            switch result {
            case .success(_):
                XCTFail("Expected failure but got success")
            case .failure(let error):
                XCTAssertEqual(error.errorCode, 37)
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
#endif
