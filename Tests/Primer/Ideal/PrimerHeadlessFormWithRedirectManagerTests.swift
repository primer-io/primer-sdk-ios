//
//  PrimerHeadlessFormWithRedirectManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class PrimerHeadlessFormWithRedirectManagerTests: XCTestCase {
    let methodTypeString = "ADYEN_IDEAL"
    var availablePaymentMethodsLoadedCompletion: (([PrimerHeadlessUniversalCheckout.PaymentMethod]?, Error?) -> Void)?

    override func tearDown() {
        super.tearDown()
        self.resetTestingEnvironment()
    }

    func testInit() {
        let subject = PrimerHeadlessUniversalCheckout.current
        PrimerInternal.shared.sdkIntegrationType = .headless
        self.resetTestingEnvironment()

        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock_client_session_ideal_id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let idealFormWithRedirectPaymentMethod = Mocks.PaymentMethods.idealFormWithRedirectPaymentMethod
        idealFormWithRedirectPaymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)

        guard let mockPrimerApiConfiguration = createMockApiConfiguration(clientSession: clientSession, mockPaymentMethods: [idealFormWithRedirectPaymentMethod]) else {
            XCTFail("Unable to start mock tokenization")
            return
        }

        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        PrimerAPIConfigurationModule.apiClient = mockApiClient

        let expectation = XCTestExpectation(description: "Successful HUC initialization")
        self.availablePaymentMethodsLoadedCompletion = { _, _ in
            XCTAssertTrue(subject.listAvailablePaymentMethodsTypes()?.contains(PrimerPaymentMethodType.adyenIDeal.rawValue) ?? false)
            PrimerPaymentMethodType.allCases.forEach {
                let manager = PrimerHeadlessUniversalCheckout.ComponentWithRedirectManager()
                if $0 == .adyenIDeal {
                    XCTAssertNotNil(try? manager.provideBanksComponent(paymentMethodType: $0.rawValue))
                    let wrapper = PrimerHeadlessBanksComponentWrapper(manager: PrimerHeadlessUniversalCheckout.ComponentWithRedirectManager(), paymentMethodType: $0.rawValue)
                    XCTAssertNotNil(wrapper.banksComponent)
                } else {
                    XCTAssertNil(try? manager.provideBanksComponent(paymentMethodType: $0.rawValue))
                }
            }
        }

        PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken, delegate: self, uiDelegate: self) { _, _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
    }

    func testProvideInvalidMethod() {
        let manager = PrimerHeadlessUniversalCheckout.ComponentWithRedirectManager()
        XCTAssertNil(try? manager.provide(paymentMethodType: "invalid_payment_method"))
    }

}

extension PrimerHeadlessFormWithRedirectManagerTests: TokenizationTestDelegate {
    func cleanup() {
        self.availablePaymentMethodsLoadedCompletion = nil
    }
}

extension PrimerHeadlessFormWithRedirectManagerTests: PrimerHeadlessUniversalCheckoutDelegate, PrimerHeadlessUniversalCheckoutUIDelegate {
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerSDK.PrimerCheckoutData) {}
    func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]) {
        self.availablePaymentMethodsLoadedCompletion?(paymentMethods, nil)
    }
}
