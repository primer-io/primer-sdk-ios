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
        
    }

    override func tearDown() {
        restartPrimerConfiguration()
        super.tearDown()
    }

    func test_tokenizeHeadless_success() {
        prepareConfigurations()
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
        prepareConfigurations()
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
    
    func test_tokenization_validation_success() {
        prepareConfigurations()
        do {
            try tokenizationService.validate()
        } catch {
            XCTFail("Result should not fail with error")
        }
    }
    
    func test_tokenization_validation_decodedToken_failure() {
        prepareConfigurations(isClientSessionEmpty: false, hasDecodedToken: false)
        do {
            try tokenizationService.validate()
        } catch {
            //XCTFail("Result should not fail with error")
        }
    }
    
    func test_tokenization_validation_amount_failure() {
        prepareConfigurations(isClientSessionEmpty: true, emptyMerchantAmmount: true, emptyTotalOrderAmmount: true)
        do {
            try tokenizationService.validate()
        } catch {
            guard let primerError = error as? PrimerError else {
                XCTFail("Error should be of type PrimerError")
                return
            }
            
            switch primerError {
            case .invalidSetting(let name, _, _, _):
                XCTAssertTrue(name == "amount")
            default:
                XCTFail("primerError should be of type invalidSetting")
            }
        }
    }
    
    func test_tokenization_validation_currency_failure() {
        prepareConfigurations(isClientSessionEmpty: true, emptyCurrencyCode: true)
        do {
            try tokenizationService.validate()
        } catch {
            guard let primerError = error as? PrimerError else {
                XCTFail("Error should be of type PrimerError")
                return
            }
            
            switch primerError {
            case .invalidSetting(let name, _, _, _):
                XCTAssertTrue(name == "currency")
            default:
                XCTFail("primerError should be of type invalidSetting")
            }
        }
    }
    
    func test_tokenization_validation_lineItems_failure() {
        prepareConfigurations(isClientSessionEmpty: true, emptyLineItems: true)
        do {
            try tokenizationService.validate()
        } catch {
            guard let primerError = error as? PrimerError else {
                XCTFail("Error should be of type PrimerError")
                return
            }
            
            switch primerError {
            case .invalidValue(let key, _, _, _):
                XCTAssertTrue(key == "lineItems")
            default:
                XCTFail("primerError should be of type invalidValue")
            }
        }
    }
    
    func test_tokenization_validation_lineItems_total_failure() {
        prepareConfigurations(isClientSessionEmpty: true, emptyOrderAmount: true)
        do {
            try tokenizationService.validate()
        } catch {
            guard let primerError = error as? PrimerError else {
                XCTFail("Error should be of type PrimerError")
                return
            }
            
            switch primerError {
            case .invalidValue(let key, _, _, _):
                XCTAssertTrue(key == "settings.orderItems")
            default:
                XCTFail("primerError should be of type invalidValue")
            }
        }
    }

}

extension ACHTokenizationServiceTests {
    private func setupPrimerConfiguration(paymentMethod: PrimerPaymentMethod, apiConfiguration: PrimerAPIConfiguration, hasDecodedToken: Bool) {
        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])
        
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (apiConfiguration, nil)
        
        if hasDecodedToken {
            AppState.current.clientToken = MockAppState.mockClientToken
        }
        
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        
        if hasDecodedToken {
            PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        }
        
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
        TokenizationService.apiClient = mockApiClient
        
        tokenizationService = ACHTokenizationService(paymentMethod: paymentMethod)
    }

    private func prepareConfigurations(isClientSessionEmpty: Bool = false,
                                       hasDecodedToken: Bool = true,
                                       emptyMerchantAmmount: Bool = false,
                                       emptyTotalOrderAmmount: Bool = false,
                                       emptyLineItems: Bool = false,
                                       emptyOrderAmount: Bool = false,
                                       emptyCurrencyCode: Bool = false) {
        mockApiClient = MockPrimerAPIClient()
        
        var clientSession: ClientSession.APIResponse?
        
        if isClientSessionEmpty {
            clientSession = ACHMocks.getEmptyClientSession(emptyMerchantAmmount: emptyMerchantAmmount,
                                                           emptyTotalOrderAmmount: emptyTotalOrderAmmount,
                                                           emptyLineItems: emptyLineItems,
                                                           emptyOrderAmount: emptyOrderAmount,
                                                           emptyCurrencyCode: emptyCurrencyCode)
        } else {
            clientSession = ACHMocks.getClientSession()
        }
        
        PrimerInternal.shared.sdkIntegrationType = .headless
        PrimerInternal.shared.intent = .checkout

        let mockPrimerApiConfiguration = Mocks.createMockAPIConfiguration(
            clientSession: clientSession,
            paymentMethods: [ACHMocks.stripeACHPaymentMethod])
        
        mockPrimerApiConfiguration.paymentMethods?[0].baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        setupPrimerConfiguration(paymentMethod: ACHMocks.stripeACHPaymentMethod, apiConfiguration: mockPrimerApiConfiguration, hasDecodedToken: hasDecodedToken)
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
