//
//  SDKSessionHelper.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 14/11/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation
@testable import PrimerSDK

final class SDKSessionHelper {

    private init() {}

    static func setUp(withPaymentMethods paymentMethods: [PrimerPaymentMethod]? = nil,
                      order: ClientSession.Order? = nil,
                      showTestId: Bool = false) {
        let paymentMethods = paymentMethods ?? [
            Mocks.PaymentMethods.paymentCardPaymentMethod
        ]
        let session = ClientSession.APIResponse(clientSessionId: "client_session_id",
                                                paymentMethod: nil,
                                                order: order,
                                                customer: nil,
                                                testId: showTestId ? "test_id" : nil)
        let apiConfig = PrimerAPIConfiguration(coreUrl: "core_url",
                                               pciUrl: "pci_url",
                                               binDataUrl: "bindata_url",
                                               assetsUrl: "https://assets.staging.core.primer.io",
                                               clientSession: session,
                                               paymentMethods: paymentMethods,
                                               primerAccountId: "account_id",
                                               keys: nil,
                                               checkoutModules: nil)
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        PrimerAPIConfigurationModule.apiConfiguration = apiConfig
    }

    static func tearDown() {
        PrimerAPIConfigurationModule.apiConfiguration = nil
        PrimerAPIConfigurationModule.clientToken = nil
    }

    static func test(withPaymentMethods paymentMethods: [PrimerPaymentMethod]? = nil,
                     order: ClientSession.Order? = nil,
                     _ completion: () throws -> Void) throws {
        setUp(withPaymentMethods: paymentMethods, order: order)
        try completion()
        tearDown()
    }

    static func test(withPaymentMethods paymentMethods: [PrimerPaymentMethod]? = nil,
                     _ completion: @escaping (_ done: @escaping () -> Void) throws -> Void) throws {
        setUp(withPaymentMethods: paymentMethods)
        try completion(tearDown)
    }

    static func updateAllowedCardNetworks(cardNetworks: [CardNetwork]) {
        PrimerAPIConfigurationModule.apiConfiguration?.clientSession = .init(
            clientSessionId: "",
            paymentMethod: .init(vaultOnSuccess: false,
                                 options: nil,
                                 orderedAllowedCardNetworks: cardNetworks.map { $0.rawValue }),
            order: nil,
            customer: nil,
            testId: nil
        )
    }

}
