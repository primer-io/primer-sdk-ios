//
//  CardButtonViewModelTests.swift
//  
//
//  Created by Jack Newcombe on 28/05/2024.
//

import XCTest
@testable import PrimerSDK

final class CardButtonViewModelTests: XCTestCase {

    override func tearDown() {
        SDKSessionHelper.tearDown()
    }

    func testViewModelSurchargeWithValidOptions() {
        setupSession(network: .visa, hasCardOptions: true, surcharge: 1234)

        let viewModel = CardButtonViewModel(network: "VISA",
                                            cardholder: "John Appleseed",
                                            last4: "1234",
                                            expiry: "01/30",
                                            imageName: .visa,
                                            paymentMethodType: .paymentCard)

        XCTAssertEqual(viewModel.surCharge, 1234)
    }

    func testViewModelSurchargeWithInvalidOptions_invalidNetwork() {
        setupSession(network: nil, hasCardOptions: true, surcharge: 1234)

        let viewModel = CardButtonViewModel(network: "VISA",
                                            cardholder: "John Appleseed",
                                            last4: "1234",
                                            expiry: "01/30",
                                            imageName: .visa,
                                            paymentMethodType: .paymentCard)

        XCTAssertNil(viewModel.surCharge)
    }

    func testViewModelSurchargeWithInvalidOptions_invalidNetworkAndSurcharge() {
        setupSession(network: nil, hasCardOptions: true, surcharge: nil)

        let viewModel = CardButtonViewModel(network: "VISA",
                                            cardholder: "John Appleseed",
                                            last4: "1234",
                                            expiry: "01/30",
                                            imageName: .visa,
                                            paymentMethodType: .paymentCard)

        XCTAssertNil(viewModel.surCharge)
    }

    func testViewModelSurchargeWithInvalidOptions_noCardOptions() {
        setupSession(network: nil, hasCardOptions: false, surcharge: nil)

        let viewModel = CardButtonViewModel(network: "VISA",
                                            cardholder: "John Appleseed",
                                            last4: "1234",
                                            expiry: "01/30",
                                            imageName: .visa,
                                            paymentMethodType: .paymentCard)

        XCTAssertNil(viewModel.surCharge)
    }

    func testViewModelSurchargeWithInvalidOptions_invalidSurcharge() {
        setupSession(network: .visa, hasCardOptions: true, surcharge: nil)

        let viewModel = CardButtonViewModel(network: "VISA",
                                            cardholder: "John Appleseed",
                                            last4: "1234",
                                            expiry: "01/30",
                                            imageName: .visa,
                                            paymentMethodType: .paymentCard)

        XCTAssertNil(viewModel.surCharge)
    }

    // MARK: Helpers

    private func setupSession(network: CardNetwork?, hasCardOptions: Bool, surcharge: Int? = nil) {
        SDKSessionHelper.setUp(withPaymentMethods: [
            createPaymentMethod(hasCardOptions: hasCardOptions, surcharge: surcharge)
        ], paymentMethodOptions: [[
            "type": PrimerPaymentMethodType.paymentCard.rawValue,
            "networks": ((network != nil || surcharge != nil) ? [
                [
                    "type": network?.rawValue.lowercased() as Any,
                    "surcharge": surcharge as Any
                ]
            ] : nil) as Any
        ]])
    }

    private func createPaymentMethod(hasCardOptions: Bool, surcharge: Int?) -> PrimerPaymentMethod {
        let options = CardOptions(threeDSecureEnabled: false,
                                  threeDSecureToken: nil,
                                  threeDSecureInitUrl: nil,
                                  threeDSecureProvider: "",
                                  processorConfigId: "processor_config_id",
                                  captureVaultedCardCvv: false)
        return .init(id: "id",
                     implementationType: .nativeSdk,
                     type: PrimerPaymentMethodType.paymentCard.rawValue,
                     name: "card",
                     processorConfigId: "processor_config_id",
                     surcharge: 1234,
                     options: hasCardOptions ? options : nil,
                     displayMetadata: nil)
    }
}
