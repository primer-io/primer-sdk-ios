//
//  File.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockVaultCheckoutViewModel: VaultCheckoutViewModelProtocol {
    var mandate: DirectDebitMandate {
        return DirectDebitMandate()
    }

    var availablePaymentOptions: [PaymentMethodTokenizationViewModelProtocol] {
        return []
    }

    var amountStringed: String? {
        return nil
    }

    var paymentMethods: [PaymentMethodToken] {
        return []
    }

    var selectedPaymentMethodId: String {
        return "id"
    }

    func loadConfig(_ completion: @escaping (Error?) -> Void) {

    }

    func authorizePayment(_ completion: @escaping (Error?) -> Void) {

    }
}

#endif
