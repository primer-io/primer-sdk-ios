//
//  PaymentMethodConfigService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

import XCTest
@testable import PrimerSDK

class PaymentMethodConfigServiceTests: XCTestCase {
    
    func test_fetchConfig_updates_paymentMethodConfig_and_viewModels() throws {
        let config = PaymentMethodConfig(
            coreUrl: "coreUrl",
            pciUrl: "pciUrl",
            paymentMethods: [
                ConfigPaymentMethod(id: "id123", type: .PAYMENT_CARD)
            ]
        )
        
        let data: Data = try JSONEncoder().encode(config)
        let state = MockAppState()
        
        MockLocator.registerDependencies()
        DependencyContainer.register(MockAPIClient(with: data, throwsError: false) as APIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = PaymentMethodConfigService()
        
        service.fetchConfig({ error in })
        
        XCTAssertEqual(state.paymentMethodConfig?.coreUrl, config.coreUrl)
        XCTAssertEqual(state.viewModels.count, 1)
    }
}
