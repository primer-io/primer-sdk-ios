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
        let config = PaymentMethodConfig(
            coreUrl: "coreUrl",
            pciUrl: "pciUrl",
            paymentMethods: [
                ConfigPaymentMethod(id: "id123", options: nil, processorConfigId: nil, type: .paymentCard)
            ],
            keys: nil
        )

        let data: Data = try JSONEncoder().encode(config)
        let state = MockAppState()

        MockLocator.registerDependencies()
        DependencyContainer.register(MockPrimerAPIClient(with: data, throwsError: false) as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)

        let service = PaymentMethodConfigService()

        service.fetchConfig({ _ in })

        XCTAssertEqual(state.paymentMethodConfig?.coreUrl, config.coreUrl)
        XCTAssertEqual(state.viewModels.count, 1)
    }
}

#endif
