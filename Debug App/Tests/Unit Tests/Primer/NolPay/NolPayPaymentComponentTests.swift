//
//  NolPayPaymentComponentTests.swift
//  Debug App Tests
//
//  Created by Boris on 10.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerNolPaySDK)
import XCTest
@testable import PrimerSDK
import PrimerNolPaySDK

class NolPayPaymentComponentTests: XCTestCase {
    
    var sut: NolPayPaymentComponent!
    
    override func setUp() {
        super.setUp()
        sut = NolPayPaymentComponent()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testUpdateCollectedData_ValidData_ShouldUpdateInternalVariables() {
        let data = NolPayPaymentCollectableData.paymentData(cardNumber: "1234567812345678", mobileNumber: "+1231231231231")
        sut.updateCollectedData(collectableData: data)
        
        XCTAssertEqual(sut.cardNumber, "1234567812345678")
        XCTAssertEqual(sut.mobileNumber, "+1231231231231")
        
    }
    
    func testSubmit_MissingCardNumber_ShouldCallErrorDelegate() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        
        sut.submit()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived)
    }
    
    func testUpdateCollectedData_InvalidPhoneNumber_ShouldReturnPhoneValidationError() {
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        let data = NolPayPaymentCollectableData.paymentData(cardNumber: "1234567812345678", mobileNumber: "+1231231231231")
        sut.updateCollectedData(collectableData: data)
        
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
        XCTAssertNotNil(mockValidationDelegate.validationsReceived)
    }
        
    func testValidationTriggeredWhenUpdatingPaymentData() {
        // Given
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        // When
        sut.updateCollectedData(collectableData: .paymentData(cardNumber: "", mobileNumber: ""))
        
        // Then
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled, "Validation was not triggered when updating payment data.")
    }
    
    func testInvalidPaymentDataValidationErrorReceived() {
        // Given
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        // When
        sut.updateCollectedData(collectableData: .paymentData(cardNumber: "", mobileNumber: ""))
        
        // Then
        XCTAssertNotNil(mockValidationDelegate.validationsReceived, "No validations received.")
    }
    
    func testSubmitWithNilCardNumber() {
        sut.cardNumber = nil
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived, "Expected an error when card number is nil.")
    }
    
    func testSubmitWithNilMobileNumber() {
        sut.cardNumber = "1234567890123456"
        sut.mobileNumber = nil
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived, "Expected an error when mobile number is nil.")
    }
    
    func testSubmitWithNilCountryDiallingCode() {
        sut.cardNumber = "1234567890123456"
        sut.mobileNumber = "+1231231231231"
        sut.countryCode = nil
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived, "Expected an error when country dialling code is nil.")
    }
        
    func testFailedPaymentRequest() {
        // Mock the payment request to always fail
        let mockPaymentMethod = MockNolPayTokenizationViewModel(config: PrimerPaymentMethod(id: "1", implementationType: PrimerPaymentMethod.ImplementationType.nativeSdk, type: "", name: "", processorConfigId: nil, surcharge: nil, options: nil, displayMetadata: nil))
        let expectedError = PrimerError.nolError(code: "unknown",
                                                 message: "Payment failed for test",
                                                 userInfo: nil,
                                                 diagnosticsId: UUID().uuidString)
        mockPaymentMethod.resultToReturn = .failure(expectedError)
        sut.tokenizationViewModel = mockPaymentMethod
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived, "Expected an error when payment fails.")
        XCTAssertTrue(mockErrorDelegate.errorReceived is PrimerError, "Expected error type to be PrimerError.")
    }
    
}
#endif
