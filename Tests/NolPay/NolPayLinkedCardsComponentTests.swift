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
        let component = NolPayLinkedCardsComponent()
        XCTAssertNotNil(component)
    }

    func testGetLinkedCardsWithValidMobileNumber() {

        let paymentMethod = Mocks.PaymentMethods.nolPaymentMethod
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.mockSuccessfulResponses()
        let component = NolPayLinkedCardsComponent(apiClient: mockApiClient)

        let mockNolPay = MockPrimerNolPay(appId: "123", isDebug: true, isSandbox: true, appSecretHandler: { _, _ in
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

        waitForExpectations(timeout: 5, handler: nil) // Increased timeout due to potential async start operation
    }

    func testGetLinkedCardsFor_WhenSDKNotAvailable() {
        let paymentMethod = Mocks.PaymentMethods.nolPaymentMethod
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.testFetchNolSdkSecretResult = (nil, PrimerError.nolError(code: "", message: "", userInfo: nil, diagnosticsId: ""))
        let component = NolPayLinkedCardsComponent(apiClient: mockApiClient)

        let mockNolPay = MockPrimerNolPay(appId: "123", isDebug: true, isSandbox: true, appSecretHandler: { _, _ in
            return "appSecret"
        })
        mockNolPay.mockCards = []

        let mockPhoneMetadataService = MockPhoneMetadataService()
        mockPhoneMetadataService.resultToReturn = .success((.valid, "+123", "1234567890"))
        component.phoneMetadataService = mockPhoneMetadataService
        component.nolPay = mockNolPay

        let expectation = self.expectation(description: "Get Linked Cards For SDK Not Available")

        component.getLinkedCardsFor(mobileNumber: "+1234567890") { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                if case PrimerError.nolError = error {
                    // This is expected, checking for specific error type or message might be useful
                } else {
                    XCTFail("Expected PrimerError.nolError but got \(error)")
                }
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
#endif
