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
                PaymentMethodConfig(id: "id123", options: nil, processorConfigId: "config_id", type: .paymentCard)
            ],
            keys: nil
        )

        let data: Data = try JSONEncoder().encode(config)
        let state = MockAppState()

        MockLocator.registerDependencies()
        Primer.shared.showUniversalCheckout(on: UIViewController(), clientToken: nil)
        DependencyContainer.register(MockPrimerAPIClient(with: data, throwsError: false) as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)

        let service = PaymentMethodConfigService()

        service.fetchConfig({ _ in })

        XCTAssertEqual(state.paymentMethodConfig?.coreUrl, config.coreUrl)
        XCTAssertEqual(PrimerConfiguration.paymentMethodConfigViewModels.count, 1)
    }
}

#endif
