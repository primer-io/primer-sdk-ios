//
//  PaymentMethodConfigService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class PaymentMethodConfigServiceTests: XCTestCase {

    func test_fetchConfig_updates_paymentMethodConfig_and_viewModels() throws {
        let config = PrimerAPIConfiguration(
            coreUrl: "coreUrl",
            pciUrl: "pciUrl",
            clientSession: nil,
            paymentMethods: [
                PrimerPaymentMethod(id: "payment-card-id", implementationType: .nativeSdk, type: "PAYMENT_CARD", name: "Payment Card", processorConfigId: "payment-card-processor_config-id", surcharge: nil, options: nil, displayMetadata: nil)
            ],
            keys: nil,
            checkoutModules: nil
        )

        let state = MockAppState(apiConfiguration: config)

        MockLocator.registerDependencies()
        DependencyContainer.register(state as AppStateProtocol)
        Primer.shared.showUniversalCheckout(clientToken: "")

        XCTAssertEqual(state.apiConfiguration?.coreUrl, "coreUrl")
        XCTAssertEqual(PrimerAPIConfiguration.paymentMethodConfigViewModels.count, 1)
    }
}

#endif
