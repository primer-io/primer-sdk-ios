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
        let clientToken = ClientToken(
            accessToken: "bla",
            configurationUrl: "bla",
            paymentFlow: "bla",
            threeDSecureInitUrl: "bla",
            threeDSecureToken: "bla",
            coreUrl: "bla",
            pciUrl: "bla",
            env: "bla"
        )
        let config = PaymentMethodConfig(
            coreUrl: "coreUrl",
            pciUrl: "pciUrl",
            paymentMethods: [
                ConfigPaymentMethod(id: "id123", type: .PAYMENT_CARD)
            ]
        )
        let data: Data = try JSONEncoder().encode(config)
        let api = MockAPIClient(with: data, throwsError: false)
        
        let service = PaymentMethodConfigService(with: api)
        
        service.fetchConfig(with: clientToken, { error in })
        
        XCTAssertEqual(service.paymentMethodConfig?.coreUrl, config.coreUrl)
        XCTAssertEqual(service.viewModels.count, 1)
    }
}
