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
        let config = PrimerConfiguration(
            coreUrl: "coreUrl",
            pciUrl: "pciUrl",
            clientSession: nil,
            paymentMethods: [
                PaymentMethod.Configuration(id: "id123", options: nil, processorConfigId: "config_id", type: .paymentCard)
            ],
            keys: nil,
            checkoutModules: nil
        )

        let state = MockAppState(decodedClientToken: nil, primerConfiguration: config)

        MockLocator.registerDependencies()
        Primer.shared.showUniversalCheckout(on: UIViewController())

        XCTAssertEqual(state.primerConfiguration?.coreUrl, "coreUrl")
        XCTAssertEqual(PrimerConfiguration.paymentMethodConfigViewModels.count, 1)
    }
}

#endif
