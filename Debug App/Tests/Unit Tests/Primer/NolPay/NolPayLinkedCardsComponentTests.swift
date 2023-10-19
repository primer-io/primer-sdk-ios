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
    
    func testGetLinkedCardsFor_Success() {
        let mockNolPay = MockPrimerNolPay(appId: "appId", isDebug: true, isSandbox: true) { sdkId, deviceId in
            return try await withCheckedThrowingContinuation { continuation in
                continuation.resume(returning: "appSecret")
            }
        }
        let card = PrimerNolPayCard(cardNumber: "1234", expiredTime: "12/34")
        mockNolPay.mockCards = [card]
        
        let component = NolPayLinkedCardsComponent(isDebug: true)
        component.nolPay = mockNolPay // Inject mock object
        
        let expectation = self.expectation(description: "Get Linked Cards For Success")
        
        component.getLinkedCardsFor(phoneCountryDiallingCode: "+1", mobileNumber: "1234567890") { result in
            switch result {
            case .success(let cards):
                XCTAssertEqual(cards.first?.cardNumber, "1234")
                XCTAssertEqual(cards.first?.expiredTime, "12/34")
            case .failure(_):
                XCTFail("Expected success but got failure")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGetLinkedCardsFor_WhenSDKNotAvailable() {
        let component = NolPayLinkedCardsComponent(isDebug: true)
        component.nolPay = nil // Setting nolPay to nil to simulate SDK unavailability
        
        let expectation = self.expectation(description: "Get Linked Cards For SDK Not Available")
        
        component.getLinkedCardsFor(phoneCountryDiallingCode: "+1", mobileNumber: "1234567890") { result in
            switch result {
            case .success(_):
                XCTFail("Expected failure but got success")
            case .failure(let error):
                // TODO: (NOL) update error
                XCTAssertEqual(error.errorCode, 37)
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
#endif
