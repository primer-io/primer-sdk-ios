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
    
    static func setUp(withPaymentMethods paymentMethods: [PrimerPaymentMethod]? = nil) {
        let paymentMethods = paymentMethods ?? [
            Mocks.PaymentMethods.paymentCardPaymentMethod
        ]
        let session = ClientSession.APIResponse(clientSessionId: "client_session_id",
                                                paymentMethod: nil,
                                                order: nil,
                                                customer: nil,
                                                testId: nil)
        let apiConfig = PrimerAPIConfiguration(coreUrl: "core_url",
                                               pciUrl: "pci_url",
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
    
    static func updateAllowedCardNetworks(cardNetworks: [CardNetwork]) {
        PrimerAPIConfigurationModule.apiConfiguration?.clientSession = .init(
            clientSessionId: "",
            paymentMethod: .init(vaultOnSuccess: false,
                                 options: nil),
            order: nil,
            customer: nil,
            testId: nil
        )
    }

}
