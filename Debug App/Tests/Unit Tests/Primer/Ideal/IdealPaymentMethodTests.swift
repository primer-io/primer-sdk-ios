//
//  IdealPaymentMethodTests.swift
//  Debug App Tests
//
//  Created by Alexandra Lovin on 10.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class IdealPaymentMethodTests: XCTestCase {

    var availablePaymentMethodsLoadedCompletion: (([PrimerHeadlessUniversalCheckout.PaymentMethod]?, Error?) -> Void)?

    func test_AvailablePaymentMethods() throws {
        let subject = PrimerHeadlessUniversalCheckout.current

        PrimerInternal.shared.sdkIntegrationType = .headless

        self.resetTestingEnvironment()

        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock_client_session_ideal_id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil),
            order: nil,
            customer: nil,
            testId: nil)
        guard let mockPrimerApiConfiguration = createMockApiConfiguration(clientSession: clientSession, mockPaymentMethods: [Mocks.PaymentMethods.idealFormWithRedirectPaymentMethod]) else {
            XCTFail("Unable to start mock tokenization")
            return
        }

        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient

        let expectation = XCTestExpectation(description: "Successful HUC initialization")

        PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken, delegate: self, uiDelegate: self) { availablePaymentMethods, err in
            if let err = err {
                XCTAssert(false, "SDK failed with error \(err.localizedDescription) while it should have succeeded.")
            } else if let availablePaymentMethods = availablePaymentMethods {
                XCTAssert(availablePaymentMethods.count == mockPrimerApiConfiguration.paymentMethods?.count, "SDK should have returned the mocked payment methods.")
            } else {
                XCTAssert(false, "SDK should have returned an error or payment methods.")
            }
            expectation.fulfill()
        }
        self.availablePaymentMethodsLoadedCompletion = { _, _ in
            XCTAssertTrue(subject.listAvailablePaymentMethodsTypes()?.contains(PrimerPaymentMethodType.adyenIDeal.rawValue) ?? false)
        }
        wait(for: [expectation], timeout: 10)

    }

    override func tearDown() {
        PrimerInternal.shared.sdkIntegrationType = .dropIn
        self.resetTestingEnvironment()
    }

}

extension IdealPaymentMethodTests: PrimerHeadlessUniversalCheckoutDelegate {
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerSDK.PrimerCheckoutData) {}
    func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]) {
        self.availablePaymentMethodsLoadedCompletion?(paymentMethods, nil)
    }
}

extension IdealPaymentMethodTests: PrimerHeadlessUniversalCheckoutUIDelegate {
}

extension IdealPaymentMethodTests: TokenizationTestDelegate {
    func cleanup() {
        self.availablePaymentMethodsLoadedCompletion = nil
    }
}
