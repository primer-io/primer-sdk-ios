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
                PaymentMethodConfig(id: "id123", options: nil, processorConfigId: "config_id", type: .paymentCard)
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
