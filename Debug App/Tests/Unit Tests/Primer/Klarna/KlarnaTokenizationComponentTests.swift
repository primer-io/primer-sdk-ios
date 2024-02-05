//
//  KlarnaTokenizationComponentTests.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 05.02.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class KlarnaTokenizationComponentTests: XCTestCase {
    
    var tokenizationComponent: KlarnaTokenizationComponent!
    var paymentMethod: PrimerPaymentMethod!
    
    override func setUp() {
        super.setUp()
        paymentMethod = Mocks.PaymentMethods.klarnaPaymentMethod
        let clientSession = KlarnaTestsMocks.getClientSession()
        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: successApiConfiguration)
    }
    
    override func tearDown() {
        tokenizationComponent = nil
        paymentMethod = nil
        super.tearDown()
    }
    
    func test_validateWithSuccess() {
        let clientSession = KlarnaTestsMocks.getClientSession()
        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: successApiConfiguration)
        
        XCTAssertNoThrow(try tokenizationComponent.validate(), "Validation should not throw any error.")
    }
    
    func test_validateWithError_lineItems() {
        let clientSession = KlarnaTestsMocks.getClientSession(hasItems: false)
        let failingApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: failingApiConfiguration)
        
        let expectedError = getInvalidValueError(key: "lineItems")
        
        XCTAssertThrowsError(try tokenizationComponent.validate()) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Validation error is expected here.")
            }
        }
    }
    
    func test_validateWithError_orderItemsAmount() {
        let clientSession = KlarnaTestsMocks.getClientSession(hasLineItemAmout: false)
        let failingApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: failingApiConfiguration)
        
        let expectedError = getInvalidValueError(key: "settings.orderItems")
        
        XCTAssertThrowsError(try tokenizationComponent.validate()) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Validation error is expected here.")
            }
        }
    }
    
    func test_validateWithError_amount() {
        let clientSession = KlarnaTestsMocks.getClientSession(hasAmount: false)
        let failingApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: failingApiConfiguration)
        
        let expectedError = getInvalidSettingError(name: "amount")
        
        XCTAssertThrowsError(try tokenizationComponent.validate()) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Validation error is expected here.")
            }
        }
    }
    
    func test_validateWithError_currency() {
        let clientSession = KlarnaTestsMocks.getClientSession(hasCurrency: false)
        let failingApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: failingApiConfiguration)
        
        let expectedError = getInvalidSettingError(name: "currency")
        
        XCTAssertThrowsError(try tokenizationComponent.validate()) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Validation error is expected here.")
            }
        }
    }
    
    func test_createPaymentSessionSuccess() {
        let clientSession = KlarnaTestsMocks.getClientSession()
        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: successApiConfiguration)
        
        let expectation = XCTestExpectation(description: "Successful Create Klarna Payment Session")
        
        tokenizationComponent.createPaymentSession(attachment: nil) { response in
            switch response {
            case .success(let result):
                XCTAssertNotNil(result, "Result should not be nil")
            case .failure(let error):
                XCTFail("Request failed with: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func test_authorizePaymentSessionSuccess() {
        let clientSession = KlarnaTestsMocks.getClientSession()
        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: successApiConfiguration)
        
        tokenizationComponent.setSessionId(paymentSessionId: "mock-session-id")
        
        let expectation = XCTestExpectation(description: "Successful Create Klarna Payment Session")
        
        tokenizationComponent.authorizePaymentSession(authorizationToken: "") { response in
            switch response {
            case .success(let result):
                XCTAssertNotNil(result, "Result should not be nil")
            case .failure(let error):
                XCTFail("Request failed with: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    
}

extension KlarnaTokenizationComponentTests {
    private func setupPrimerConfiguration(paymentMethod: PrimerPaymentMethod, apiConfiguration: PrimerAPIConfiguration) {
        restartPrimerConfiguration()
        
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchConfigurationWithActionsResult = (apiConfiguration, nil)
        mockApiClient.mockSuccessfulResponses()
        
        AppState.current.clientToken = KlarnaTestsMocks.clientToken
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.clientToken = KlarnaTestsMocks.clientToken
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
        
        tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
    }
    
    private func restartPrimerConfiguration() {
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
        PrimerAPIConfigurationModule.apiClient = nil
        tokenizationComponent = nil
    }
    
    private func getInvalidTokenError() -> PrimerError {
        let error = PrimerError.invalidClientToken(
            userInfo: self.getErrorUserInfo(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
    
    func getInvalidValueError(
        key: String,
        value: Any? = nil
    ) -> PrimerError {
        let error = PrimerError.invalidValue(
            key: key,
            value: value,
            userInfo: self.getErrorUserInfo(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
    
    func getInvalidSettingError(
        name: String
    ) -> PrimerError {
        let error = PrimerError.invalidSetting(
            name: name,
            value: nil,
            userInfo: self.getErrorUserInfo(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
    
    private func getErrorUserInfo() -> [String: String] {
        return [
            "file": #file,
            "class": "\(Self.self)",
            "function": #function,
            "line": "\(#line)"
        ]
    }
}

#endif
