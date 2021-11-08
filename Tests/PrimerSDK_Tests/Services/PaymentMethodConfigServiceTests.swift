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
        MockLocator.registerDependencies()
        Primer.shared.showUniversalCheckout(on: UIViewController(), clientToken: nil)

        let state: AppStateProtocol = DependencyContainer.resolve()
        XCTAssertEqual(state.paymentMethodConfig?.coreUrl, "url")
        XCTAssertEqual(PrimerConfiguration.paymentMethodConfigViewModels.count, 1)
    }
}

#endif
