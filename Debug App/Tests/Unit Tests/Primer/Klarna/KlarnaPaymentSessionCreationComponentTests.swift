//
//  KlarnaPaymentSessionCreationComponentTests.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 28.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class KlarnaPaymentSessionCreationComponentTests: XCTestCase {

    var sut: KlarnaPaymentSessionCreationComponent!
    var tokenizationComponent: KlarnaTokenizationComponent!
    
    override func setUp() {
        super.setUp()
        let paymentMethod = Mocks.PaymentMethods.klarnaPaymentMethod
        tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
        sut = KlarnaPaymentSessionCreationComponent(tokenizationComponent: tokenizationComponent)
    }
    
    override func tearDown() {
        sut = nil
        tokenizationComponent = nil
        super.tearDown()
    }
    
    func testInitialization_Succeeds() {
        XCTAssertNotNil(sut)
    }
    
    func testUpdateCollectedData_CustomerAccountInfo_Success() {
        let accountInfo = KlarnaTestsMocks.klarnaAccountInfo
        
        sut.updateCollectedData(collectableData: .customerAccountInfo(
            accountUniqueId: accountInfo!.accountUniqueId,
            accountRegistrationDate: accountInfo!.accountRegistrationDate.toString(),
            accountLastModified: accountInfo!.accountLastModified.toString())
        )
        
        XCTAssertEqual(sut.customerAccountInfo, accountInfo)
    }
    
    func testUpdateCollectedData_CustomerAccountInfo_AccountUniqueIdValidation() {
        let accountRegistrationDate = "2022-04-25T14:05:15.953Z"
        let accountLastModified = "2023-04-25T14:05:15.953Z"
        
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        sut.updateCollectedData(collectableData: .customerAccountInfo(
            accountUniqueId: "",
            accountRegistrationDate: accountRegistrationDate,
            accountLastModified: accountLastModified)
        )
        XCTAssertEqual(mockValidationDelegate.validationErrorsReceived.count, 1)
        
        sut.updateCollectedData(collectableData: .customerAccountInfo(
            accountUniqueId: "                ",
            accountRegistrationDate: accountRegistrationDate,
            accountLastModified: accountLastModified)
        )
        XCTAssertEqual(mockValidationDelegate.validationErrorsReceived.count, 1)
        
        sut.updateCollectedData(collectableData: .customerAccountInfo(
            accountUniqueId: "this customer account id should contain more characters then 24",
            accountRegistrationDate: accountRegistrationDate,
            accountLastModified: accountLastModified)
        )
        XCTAssertEqual(mockValidationDelegate.validationErrorsReceived.count, 1)
        
        sut.updateCollectedData(collectableData: .customerAccountInfo(
            accountUniqueId: "test@gmail.com",
            accountRegistrationDate: accountRegistrationDate,
            accountLastModified: accountLastModified)
        )
        XCTAssertEqual(mockValidationDelegate.validationsReceived, .valid)
    }
    
    func testUpdateCollectedData_CustomerAccountInfo_Dates() {
        let accountUniqueId = "test@gmail.com"
        
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        sut.updateCollectedData(collectableData: .customerAccountInfo(
            accountUniqueId: accountUniqueId,
            accountRegistrationDate: "",
            accountLastModified: "")
        )
        XCTAssertEqual(mockValidationDelegate.validationErrorsReceived.count, 1)
        
        sut.updateCollectedData(collectableData: .customerAccountInfo(
            accountUniqueId: accountUniqueId,
            accountRegistrationDate: "2024-04-25T14:05:15.953Z",
            accountLastModified: "")
        )
        XCTAssertEqual(mockValidationDelegate.validationErrorsReceived.count, 1)
        
        sut.updateCollectedData(collectableData: .customerAccountInfo(
            accountUniqueId: accountUniqueId,
            accountRegistrationDate: "2022-04-25T14:05:15.953Z",
            accountLastModified: "")
        )
        XCTAssertEqual(mockValidationDelegate.validationErrorsReceived.count, 1)
        
        sut.updateCollectedData(collectableData: .customerAccountInfo(
            accountUniqueId: accountUniqueId,
            accountRegistrationDate: "2022-04-25T14:05:15.953Z",
            accountLastModified: "2021-04-25T14:05:15.953Z")
        )
        XCTAssertEqual(mockValidationDelegate.validationErrorsReceived.count, 1)
        
        sut.updateCollectedData(collectableData: .customerAccountInfo(
            accountUniqueId: accountUniqueId,
            accountRegistrationDate: "2022-04-25T14:05:15.953Z",
            accountLastModified: "2024-04-25T14:05:15.953Z")
        )
        XCTAssertEqual(mockValidationDelegate.validationErrorsReceived.count, 1)
        
        sut.updateCollectedData(collectableData: .customerAccountInfo(
            accountUniqueId: accountUniqueId,
            accountRegistrationDate: "2022-04-25T14:05:15.953Z",
            accountLastModified: "2023-04-25T14:05:15.953Z")
        )
        XCTAssertEqual(mockValidationDelegate.validationsReceived, .valid)
    }
}
#endif
