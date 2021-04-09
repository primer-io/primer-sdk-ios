//
//  DirectCheckoutViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockDirectCheckoutViewModel: DirectCheckoutViewModelProtocol {
    var amountViewModel: AmountViewModel? {
        return AmountViewModel(amount: 200, currency: .EUR)
    }

    var paymentMethods: [PaymentMethodViewModel] = []

    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {

    }
}

#endif
