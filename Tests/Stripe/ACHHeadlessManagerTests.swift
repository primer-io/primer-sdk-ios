//
//  ACHHeadlessManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import XCTest
@testable import PrimerSDK

final class ACHHeadlessManagerTests: XCTestCase {

    var manager: PrimerHeadlessUniversalCheckout.AchManager!
    var stripeACHComponent: (any StripeAchUserDetailsComponent)!
    var mockApiClient: MockPrimerAPIClient!

    override func setUp() {
        super.setUp()
        // Prepare the client session with the current user details
        prepareConfigurations(firstName: "firstname",
                              lastName: "lastname",
                              email: "email")
    }

    override func tearDown() {
        restartPrimerConfiguration()
        super.tearDown()
    }

    func test_manager_initialization_succeed() {
        XCTAssertNotNil(manager)
    }

    func test_stripeACHComponent_initialization_succeed() {
        stripeACHComponent = try? manager.provide(paymentMethodType: ACHMocks.stripeACHPaymentMethodType)
        XCTAssertNotNil(stripeACHComponent)
    }

    func test_stripeACHComponent_initialization_with_inexistent_payment_method() {
        do {
            stripeACHComponent = try manager.provide(paymentMethodType: ACHMocks.inexistentPaymentMethod)
        } catch {
            XCTAssertNotNil(error.localizedDescription)
        }
    }

    func test_stripeACHComponent_initialization_with_wrong_payment_method() {
        do {
            stripeACHComponent = try manager.provide(paymentMethodType: ACHMocks.klarnaPaymentMethodType)
        } catch {
            XCTAssertNotNil(error.localizedDescription)
        }
    }
}

extension ACHHeadlessManagerTests {
    private func setupPrimerConfiguration(apiConfiguration: PrimerAPIConfiguration) {
        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])

        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (apiConfiguration, nil)

        AppState.current.clientToken = MockAppState.mockClientToken
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration

        manager = PrimerHeadlessUniversalCheckout.AchManager()
    }

    private func prepareConfigurations(firstName: String = "", lastName: String = "", email: String = "") {
        mockApiClient = MockPrimerAPIClient()
        PrimerInternal.shared.sdkIntegrationType = .headless
        PrimerInternal.shared.intent = .checkout

        let mockPrimerApiConfiguration = getFetchConfiguration(firstName: firstName, lastName: lastName, email: email)
        setupPrimerConfiguration(apiConfiguration: mockPrimerApiConfiguration)
    }

    private func getFetchConfiguration(firstName: String, lastName: String, email: String) -> PrimerAPIConfiguration {
        let clientSession = ACHMocks.getClientSession(firstName: firstName, lastName: lastName, email: email)

        let mockPrimerApiConfiguration = Mocks.createMockAPIConfiguration(
            clientSession: clientSession,
            paymentMethods: [ACHMocks.stripeACHPaymentMethod,
                             ACHMocks.klarnaPaymentMethod])

        mockPrimerApiConfiguration.paymentMethods?[0].baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        return mockPrimerApiConfiguration
    }

    private func restartPrimerConfiguration() {
        manager = nil
        stripeACHComponent = nil
        mockApiClient = nil
        PrimerAPIConfigurationModule.apiClient = nil
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
    }

    private func getInvalidTokenError() -> PrimerError {
        let error = PrimerError.invalidClientToken()
        ErrorHandler.handle(error: error)
        return error
    }
}
