//
//  XCTestCase+Tokenization.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

protocol TokenizationTestDelegate {
    var availablePaymentMethodsLoadedCompletion: (([PrimerHeadlessUniversalCheckout.PaymentMethod]?, Error?) -> Void)? { get set }
    func cleanup()
}

extension XCTestCase {
    // MARK: - HELPERS
    func resetTestingEnvironment() {
        PrimerHeadlessUniversalCheckout.current.delegate = nil
        PrimerHeadlessUniversalCheckout.current.uiDelegate = nil
        guard let self = self as? TokenizationTestDelegate else { return }
        self.cleanup()
    }

    @discardableResult
    func createMockApiConfiguration(clientSession: ClientSession.APIResponse, mockPaymentMethods: [PrimerPaymentMethod]) -> PrimerAPIConfiguration? {
        PrimerInternal.shared.sdkIntegrationType = .headless

        self.resetTestingEnvironment()

        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock_client_session_id",
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
        let mockPrimerApiConfiguration = Mocks.createMockAPIConfiguration(
            clientSession: clientSession,
            paymentMethods: mockPaymentMethods)

        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        PrimerAPIConfigurationModule.apiClient = mockApiClient

        return mockPrimerApiConfiguration
    }
}
