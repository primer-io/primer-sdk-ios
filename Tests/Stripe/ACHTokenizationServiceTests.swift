//
//  ACHTokenizationServiceTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import XCTest
@testable import PrimerSDK

final class ACHTokenizationServiceTests: XCTestCase {

    var sut: ACHTokenizationService!
    var mockApiClient: MockPrimerAPIClient!

    override func tearDown() {
        restartPrimerConfiguration()
        super.tearDown()
    }

    func test_tokenizeHeadless_success() async {
        prepareConfigurations()
        mockApiClient.tokenizePaymentMethodResult = (ACHMocks.primerPaymentMethodTokenData, nil)

        do {
            let tokenData = try await sut.tokenize()
            XCTAssertNotNil(tokenData, "Result should not be nil")
        } catch {
            XCTFail("Error should not be thrown")
        }
    }

    func test_tokenizeHeadless_failure() async {
        prepareConfigurations()
        let error = getInvalidTokenError()
        mockApiClient.tokenizePaymentMethodResult = (nil, error)

        do {
            _ = try await sut.tokenize()
            XCTFail("Result should fail")
        } catch {
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_tokenization_validation_success() {
        prepareConfigurations()
        do {
            try sut.validate()
        } catch {
            XCTFail("Error should not be thrown")
        }
    }

    func test_tokenization_validation_decodedToken_failure() {
        prepareConfigurations(isClientSessionEmpty: false, hasDecodedToken: false)
        do {
            try sut.validate()
            XCTFail("Error should be thrown")
        } catch {
            // Expecting an error to be thrown
        }
    }

    func test_tokenization_validation_amount_failure() {
        prepareConfigurations(isClientSessionEmpty: true, emptyMerchantAmmount: true, emptyTotalOrderAmmount: true)
        do {
            try sut.validate()
        } catch {
            guard let primerError = error as? PrimerError else {
                XCTFail("Error should be of type PrimerError")
                return
            }

            switch primerError {
            case .invalidValue(let key, _, _, _):
                XCTAssertTrue(key == "amount")
            default:
                XCTFail("primerError should be of type invalidSetting")
            }
        }
    }

    func test_tokenization_validation_currency_failure() {
        prepareConfigurations(isClientSessionEmpty: true, emptyCurrencyCode: true)
        do {
            try sut.validate()
        } catch {
            guard let primerError = error as? PrimerError else {
                XCTFail("Error should be of type PrimerError")
                return
            }

            switch primerError {
            case .invalidValue(let key, _, _, _):
                XCTAssertTrue(key == "currency")
            default:
                XCTFail("primerError should be of type invalidSetting")
            }
        }
    }

    func test_tokenization_validation_lineItems_failure() {
        prepareConfigurations(isClientSessionEmpty: true, emptyLineItems: true)
        do {
            try sut.validate()
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
            try sut.validate()
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

        PrimerAPIConfigurationModule.apiClient = mockApiClient

        if hasDecodedToken {
            PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        }

        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
        let tokenizationService = TokenizationService(apiClient: mockApiClient)

        sut = ACHTokenizationService(paymentMethod: paymentMethod, tokenizationService: tokenizationService)
    }

    private func prepareConfigurations(isClientSessionEmpty: Bool = false,
                                       hasDecodedToken: Bool = true,
                                       emptyMerchantAmmount: Bool = false,
                                       emptyTotalOrderAmmount: Bool = false,
                                       emptyLineItems: Bool = false,
                                       emptyOrderAmount: Bool = false,
                                       emptyCurrencyCode: Bool = false) {
        mockApiClient = MockPrimerAPIClient()

        let settings = PrimerSettings(paymentMethodOptions:
                                        PrimerPaymentMethodOptions(urlScheme: "test://primer.io",
                                                                   stripeOptions: PrimerStripeOptions(publishableKey: "test-pk-1234")))

        DependencyContainer.register(settings as PrimerSettingsProtocol)

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

        sut = nil
    }

    private func getInvalidTokenError() -> PrimerError {
        let error = PrimerError.invalidClientToken()
        ErrorHandler.handle(error: error)
        return error
    }

}
