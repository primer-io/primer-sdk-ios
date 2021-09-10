//
//  VaultService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockVaultService: VaultServiceProtocol {

    var paymentMethodVMs: [PaymentMethod] {
        return []
    }

    let paymentMethodsIsEmpty: Bool

    var selectedPaymentMethod: String = "tokenId"

    init(paymentMethodsIsEmpty: Bool = false, selectedPaymentMethod: String = "tokenId") {
        self.paymentMethodsIsEmpty = paymentMethodsIsEmpty
        self.selectedPaymentMethod = selectedPaymentMethod
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
