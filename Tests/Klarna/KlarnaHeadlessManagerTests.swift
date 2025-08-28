//
//  KlarnaHeadlessManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class PrimerHeadlessUniversalCheckoutKlarnaManagerTests: XCTestCase {

    var manager: PrimerHeadlessUniversalCheckout.KlarnaManager!
    var klarnaComponent: (any KlarnaComponent)!

    override func setUp() {
        super.setUp()
        prepareConfigurations()
        manager = PrimerHeadlessUniversalCheckout.KlarnaManager()
    }

    override func tearDown() {
        restartPrimerConfiguration()
        super.tearDown()
    }

    func test_manager_initialization_succeed() {
        XCTAssertNotNil(manager)
    }

    func test_klarnaComponent_initialization_succeed() {
        let sessionIntent: PrimerSessionIntent = .checkout
        klarnaComponent = try? manager.provideKlarnaComponent(with: sessionIntent)

        XCTAssertNotNil(klarnaComponent)
    }

    func test_klarnaComponent_initialization_failure_noPaymentMethod() {
        PrimerAPIConfigurationModule.apiConfiguration = Mocks.apiConfiguration
        let sessionIntent: PrimerSessionIntent = .checkout

        do {
            klarnaComponent = try manager.provideKlarnaComponent(with: sessionIntent)
            XCTFail("Should throw error")
        } catch {
            switch error {
            case PrimerError.unsupportedPaymentMethod(let paymentMethodType, _, _):
                XCTAssertEqual(paymentMethodType, "KLARNA")
            default:
                XCTFail("Expected PrimerError.unsupportedPaymentMethod")
            }
        }
    }

    func test_klarnaComponent_initialization_failure_vaultingNotEnabled() {
        let sessionIntent: PrimerSessionIntent = .vault
        PrimerAPIConfiguration.paymentMethodConfigs?
            .first(where: { $0.type == "KLARNA" })?.baseLogoImage = nil

        do {
            klarnaComponent = try manager.provideKlarnaComponent(with: sessionIntent)
            XCTFail("Should throw error")
        } catch {
            switch error {
            case PrimerError.unsupportedIntent(let intent, _):
                XCTAssertEqual(intent, .vault)
            default:
                XCTFail("Expected PrimerError.unsupportedPaymentMethod")
            }
        }
    }
}

extension PrimerHeadlessUniversalCheckoutKlarnaManagerTests {
    private func setupPrimerConfiguration(paymentMethod: PrimerPaymentMethod, apiConfiguration: PrimerAPIConfiguration) {
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchConfigurationWithActionsResult = (apiConfiguration, nil)
        mockApiClient.mockSuccessfulResponses()

        AppState.current.clientToken = KlarnaTestsMocks.clientToken
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
    }

    private func prepareConfigurations() {
        PrimerInternal.shared.intent = .checkout
        let clientSession = KlarnaTestsMocks.getClientSession()
        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        successApiConfiguration.paymentMethods?[0].baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        setupPrimerConfiguration(paymentMethod: Mocks.PaymentMethods.klarnaPaymentMethod, apiConfiguration: successApiConfiguration)
    }

    private func restartPrimerConfiguration() {
        manager = nil
        klarnaComponent = nil
        AppState.current.clientToken = nil
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
        PrimerAPIConfigurationModule.apiClient = nil
    }

    private func getInvalidTokenError() -> PrimerError {
        let error = PrimerError.invalidClientToken()
        ErrorHandler.handle(error: error)
        return error
    }
}

#endif
