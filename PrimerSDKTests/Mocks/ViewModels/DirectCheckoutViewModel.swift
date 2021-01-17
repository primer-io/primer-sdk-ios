//
//  DirectCheckoutViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

@testable import PrimerSDK

class MockDirectCheckoutViewModel: DirectCheckoutViewModelProtocol {
    var amountViewModel: AmountViewModel {
        return AmountViewModel(amount: 200, currency: .EUR)
    }
    
    var paymentMethods: [PaymentMethodViewModel] = []
    
    var theme: PrimerTheme {
        return PrimerTheme()
    }
    
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        
    }
}
