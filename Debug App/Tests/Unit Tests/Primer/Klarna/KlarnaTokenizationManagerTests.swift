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
    
//    var tokenizationComponent: KlarnaTokenizationComponent!
//    
//    override func setUp() {
//        super.setUp()
//        prepareConfigurations()
//    }
//    
//    override func tearDown() {
//        restartPrimerConfiguration()
//        super.tearDown()
//    }
//    
//    func test_tokenize_success() {
//        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: true)
//        let expectation = XCTestExpectation(description: "Successful Tokenize Klarna Payment Session")
//        
//        firstly {
//            tokenizationComponent.tokenize(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
//        }
//        .done { tokenData in
//            XCTAssertNotNil(tokenData, "Result should not be nil")
//            expectation.fulfill()
//        }
//        .catch { _ in
//            expectation.fulfill()
//        }
//        
//        wait(for: [expectation], timeout: 10.0)
//    }
//    
//    func test_tokenize_failure() {
//        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: false)
//        let expectation = XCTestExpectation(description: "Failure Tokenize Klarna Payment Session")
//        
//        firstly {
//            tokenizationComponent.tokenize(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
//        }
//        .done { tokenData in
//            XCTFail("Result should be nil")
//            expectation.fulfill()
//        }
//        .catch { error in
//            XCTAssertNotNil(error, "Error should not be nil")
//            expectation.fulfill()
//        }
//        
//        wait(for: [expectation], timeout: 10.0)
//    }
    
}

//extension KlarnaTokenizationManagerTests {
//    private func setupPrimerConfiguration(paymentMethod: PrimerPaymentMethod, apiConfiguration: PrimerAPIConfiguration) {
//        let mockApiClient = MockPrimerAPIClient()
//        mockApiClient.fetchConfigurationWithActionsResult = (apiConfiguration, nil)
//        mockApiClient.mockSuccessfulResponses()
//        
//        AppState.current.clientToken = KlarnaTestsMocks.clientToken
//        PrimerAPIConfigurationModule.apiClient = mockApiClient
//        PrimerAPIConfigurationModule.clientToken = KlarnaTestsMocks.clientToken
//        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
//        
//        tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
//    }
//    
//    private func prepareConfigurations() {
//        PrimerInternal.shared.intent = .checkout
//        let clientSession = KlarnaTestsMocks.getClientSession()
//        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
//        successApiConfiguration.paymentMethods?[0].baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
//        setupPrimerConfiguration(paymentMethod: Mocks.PaymentMethods.klarnaPaymentMethod, apiConfiguration: successApiConfiguration)
//    }
//    
//    private func restartPrimerConfiguration() {
//        AppState.current.clientToken = nil
//        PrimerAPIConfigurationModule.clientToken = nil
//        PrimerAPIConfigurationModule.apiConfiguration = nil
//        PrimerAPIConfigurationModule.apiClient = nil
//        tokenizationComponent = nil
//    }
//    
//    private func getInvalidTokenError() -> PrimerError {
//        let error = PrimerError.invalidClientToken(
//            userInfo: self.getErrorUserInfo(),
//            diagnosticsId: UUID().uuidString
//        )
//        ErrorHandler.handle(error: error)
//        return error
//    }
//    
//    private func getErrorUserInfo() -> [String: String] {
//        return [
//            "file": #file,
//            "class": "\(Self.self)",
//            "function": #function,
//            "line": "\(#line)"
//        ]
//    }
//}

#endif
