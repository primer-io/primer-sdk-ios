//
//  PaymentMethodConfigServiceTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

class PaymentMethodConfigServiceTests: XCTestCase {

    func test_fetchConfig_updates_paymentMethodConfig_and_viewModels() throws {
        let config = PrimerAPIConfiguration(
            coreUrl: "coreUrl",
            pciUrl: "pciUrl",
            binDataUrl: "binDataUrl",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [
                PrimerPaymentMethod(
                    id: "payment-card-id",
                    implementationType: .nativeSdk,
                    type: "PAYMENT_CARD",
                    name: "Payment Card",
                    processorConfigId: "payment-card-processor_config-id",
                    surcharge: nil,
                    options: nil,
                    displayMetadata: nil)
            ],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )

        let state = MockAppState(apiConfiguration: config)

        MockLocator.registerDependencies()
        DependencyContainer.register(state as AppStateProtocol)
        Primer.shared.showUniversalCheckout(clientToken: "")

        XCTAssertEqual(state.apiConfiguration?.coreUrl, "coreUrl")
    }
}
