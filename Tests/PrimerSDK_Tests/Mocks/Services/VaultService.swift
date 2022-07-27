//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockVaultService: VaultServiceProtocol {
//    var paymentMethods: [PaymentMethodToken] {
//        if (paymentMethodsIsEmpty) { return [] }
//        return [
//            PaymentMethodToken(
//                token: "tokenId",
//                analyticsId: "id",
//                tokenType: "type",
//                paymentInstrumentType: .PAYMENT_CARD,
//                paymentInstrumentData: PaymentInstrumentData(
//                    last4Digits: nil,
//                    expirationMonth: nil,
//                    expirationYear: nil,
//                    cardholderName: nil,
//                    network: nil,
//                    isNetworkTokenized: nil,
//                    binData: nil,
//                    vaultData: nil
//                )
//            )
//        ]
//    }

    var paymentMethodVMs: [PaymentMethodToken] {
        return []
    }

    let paymentMethodsIsEmpty: Bool

    var selectedPaymentMethodToken: String = "tokenId"

    init(paymentMethodsIsEmpty: Bool = false, selectedPaymentMethodToken: String = "tokenId") {
        self.paymentMethodsIsEmpty = paymentMethodsIsEmpty
        self.selectedPaymentMethodToken = selectedPaymentMethodToken
    }

    var loadVaultedPaymentMethodsCalled = false

    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void) {
        loadVaultedPaymentMethodsCalled = true
    }

    var deleteVaultedPaymentMethodCalled = false

    func deleteVaultedPaymentMethod(with id: String, _ onDeletetionSuccess: @escaping (Error?) -> Void) {
        deleteVaultedPaymentMethodCalled = true
    }
}

#endif
