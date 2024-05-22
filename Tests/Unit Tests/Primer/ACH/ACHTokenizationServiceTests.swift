//
//  ACHTokenizationServiceTests.swift
//
//
//  Created by Stefan Vrancianu on 16.05.2024.
//

import Foundation
import XCTest
@testable import PrimerSDK

final class ACHTokenizationServiceTests: XCTestCase {

    var tokenizationService: ACHTokenizationService!
    var mockApiClient: MockPrimerAPIClient!

    override func setUp() {
        super.setUp()
        prepareConfigurations()
    }

    override func tearDown() {
        restartPrimerConfiguration()
        super.tearDown()
    }

    func test_tokenizeHeadless_success() {
        mockApiClient.tokenizePaymentMethodResult = (ACHMocks.primerPaymentMethodTokenData, nil)
        let expectation = XCTestExpectation(description: "Successful Tokenize StripeACH Payment Session")

        firstly {
            tokenizationService.tokenize()
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
        let error = getInvalidTokenError()
        mockApiClient.tokenizePaymentMethodResult = (nil, error)
        let expectation = XCTestExpectation(description: "Failure Tokenize StripeACH Payment Session")

        firstly {
            tokenizationService.tokenize()
        }
        .done { _ in
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

extension ACHTokenizationServiceTests {
    private func setupPrimerConfiguration(paymentMethod: PrimerPaymentMethod, apiConfiguration: PrimerAPIConfiguration) {
        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])
        
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (apiConfiguration, nil)
        
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        TokenizationService.apiClient = mockApiClient
        
        tokenizationService = ACHTokenizationService(paymentMethod: paymentMethod)
    }

    private func prepareConfigurations() {
        mockApiClient = MockPrimerAPIClient()
        let clientSession = ACHMocks.getClientSession()
        
        PrimerInternal.shared.sdkIntegrationType = .headless
        PrimerInternal.shared.intent = .checkout

        guard let mockPrimerApiConfiguration = createMockApiConfiguration(clientSession: clientSession, mockPaymentMethods: [ACHMocks.stripeACHPaymentMethod]) else {
            XCTFail("Unable to start mock tokenization")
            return
        }
        
        mockPrimerApiConfiguration.paymentMethods?[0].baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        setupPrimerConfiguration(paymentMethod: ACHMocks.stripeACHPaymentMethod, apiConfiguration: mockPrimerApiConfiguration)
    }

    private func restartPrimerConfiguration() {
        mockApiClient = nil
        PrimerAPIConfigurationModule.apiClient = nil
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
        TokenizationService.apiClient = nil
        VaultService.apiClient = nil
        
        tokenizationService = nil
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
