//
//  KlarnaPaymentSessionCreationComponentTests.swift
//  Debug App SPM Tests
//
//  Created by Illia Khrypunov on 20.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class KlarnaPaymentSessionCreationComponentTests: XCTestCase {

    var sut: KlarnaPaymentSessionCreationComponent!
    
    override func setUp() {
        super.setUp()
        sut = KlarnaPaymentSessionCreationComponent()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testInitialization_Succeeds() {
        XCTAssertNotNil(sut)
    }
    
    func testUpdateCollectedData_CustomerAccountInfo_Success() {
        let accountInfo = PrimerKlarnaCustomerAccountInfo(
            accountUniqueId: "test@gmail.com",
            accountRegistrationDate: "2022-04-25T14:05:15.953Z".toDate(),
            accountLastModified: "2023-04-25T14:05:15.953Z".toDate()
        )
        
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
    
    func testStart_SessionTypeNil() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        
        sut.setSettings(settings: DependencyContainer.resolve())
        sut.start()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived)
    }
    
    func testStart_SettingsNil() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        
        sut.setSessionType(type: .recurringPayment)
        sut.start()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived)
    }
}
#endif
