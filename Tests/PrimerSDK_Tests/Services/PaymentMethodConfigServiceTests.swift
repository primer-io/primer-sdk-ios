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

        let state = MockAppState(decodedClientToken: nil, apiConfiguration: config)

        MockLocator.registerDependencies()
        Primer.shared.showUniversalCheckout(on: UIViewController())

        XCTAssertEqual(state.apiConfiguration?.coreUrl, "coreUrl")
        XCTAssertEqual(PrimerAPIConfiguration.paymentMethodConfigViewModels.count, 1)
    }
}

#endif
