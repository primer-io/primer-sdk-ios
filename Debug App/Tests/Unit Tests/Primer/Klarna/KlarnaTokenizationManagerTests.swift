//
//  KlarnaTokenizationManagerTests.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 05.02.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class KlarnaTokenizationManagerTests: XCTestCase {
    
    var tokenizationManager: KlarnaTokenizationManagerProtocol!
    var isTokenizationFailed: Bool = false
    
    override func setUp() {
        super.setUp()
        prepareConfigurations()
    }
    
    override func tearDown() {
        restartPrimerConfiguration()
        super.tearDown()
    }
    
    func test_tokenizeHeadless_success() {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: true)
        let expectation = XCTestExpectation(description: "Successful Tokenize Klarna Payment Session")
        tokenizationManager.mockedSuccessValue = true
        
        firstly {
            tokenizationManager.tokenizeHeadless(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { tokenData in
            XCTAssertNotNil(tokenData, "Result should not be nil")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func test_tokenizeHeadless_failure() {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: false)
        let expectation = XCTestExpectation(description: "Failure Tokenize Klarna Payment Session")
        tokenizationManager.mockedSuccessValue = false
        
        firstly {
            tokenizationManager.tokenizeHeadless(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { tokenData in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }
        .catch { error in
            XCTAssertNotNil(error, "Error should not be nil")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func test_tokenizeDropIn_success() {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: true)
        let expectation = XCTestExpectation(description: "Successful Tokenize Klarna Payment Session")
        tokenizationManager.mockedSuccessValue = true
        
        firstly {
            tokenizationManager.tokenizeDropIn(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { tokenData in
            XCTAssertNotNil(tokenData, "Result should not be nil")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func test_tokenizeDropIn_failure() {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: false)
        let expectation = XCTestExpectation(description: "Failure Tokenize Klarna Payment Session")
        tokenizationManager.mockedSuccessValue = false
        
        firstly {
            tokenizationManager.tokenizeDropIn(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { tokenData in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }
        .catch { error in
            XCTAssertNotNil(error, "Error should not be nil")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
}

extension KlarnaTokenizationManagerTests {
    private func setupPrimerConfiguration(paymentMethod: PrimerPaymentMethod, apiConfiguration: PrimerAPIConfiguration) {
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchConfigurationWithActionsResult = (apiConfiguration, nil)
        mockApiClient.mockSuccessfulResponses()
        
        AppState.current.clientToken = KlarnaTestsMocks.clientToken
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.clientToken = KlarnaTestsMocks.clientToken
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
        
        tokenizationManager = MockKlarnaTokenizationManager()
    }
    
    private func prepareConfigurations() {
        PrimerInternal.shared.intent = .checkout
        let clientSession = KlarnaTestsMocks.getClientSession()
        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        successApiConfiguration.paymentMethods?[0].baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        setupPrimerConfiguration(paymentMethod: Mocks.PaymentMethods.klarnaPaymentMethod, apiConfiguration: successApiConfiguration)
    }
    
    private func restartPrimerConfiguration() {
        AppState.current.clientToken = nil
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
        PrimerAPIConfigurationModule.apiClient = nil
        tokenizationManager = nil
    }
    
    private func getInvalidTokenError() -> PrimerError {
        let error = PrimerError.invalidClientToken(
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

class MockKlarnaTokenizationManager: KlarnaTokenizationManagerProtocol {
    var mockedSuccessValue: Bool = false
    
    let primerError = PrimerError.paymentFailed(paymentMethodType: "KLARNA", description: "payment_failed", userInfo: nil, diagnosticsId: UUID().uuidString)

    func tokenizeHeadless(customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?, offSessionAuthorizationId: String?) -> PrimerSDK.Promise<PrimerSDK.PrimerCheckoutData> {
        return Promise { seal in

            let primerCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(id: "mock-id", orderId: "ios-mock-id", paymentFailureReason: nil))

            mockedSuccessValue ? seal.fulfill(primerCheckoutData) : seal.reject(primerError)
        }
    }

    func tokenizeDropIn(customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?, offSessionAuthorizationId: String?) -> PrimerSDK.Promise<PrimerSDK.PrimerPaymentMethodTokenData> {
        return Promise { seal in

            let tokenData = KlarnaTestsMocks.primerPaymentMethodTokenData
            mockedSuccessValue ? seal.fulfill(tokenData) : seal.reject(primerError)
        }
    }
    
    
}

#endif
