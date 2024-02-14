//
//  XCTestCase+Tokenization.swift
//  Debug App Tests
//
//  Created by Alexandra Lovin on 10.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

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
                orderedAllowedCardNetworks: nil),
            order: nil,
            customer: nil,
            testId: nil)
        let mockPrimerApiConfiguration = Mocks.createMockAPIConfiguration(
            clientSession: clientSession,
            paymentMethods: mockPaymentMethods)

        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient

        return mockPrimerApiConfiguration
    }
}
