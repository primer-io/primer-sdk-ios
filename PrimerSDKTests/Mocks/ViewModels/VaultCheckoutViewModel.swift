//
//  File.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

@testable import PrimerSDK

class MockVaultCheckoutViewModel: VaultCheckoutViewModelProtocol {
    var theme: PrimerTheme { return PrimerTheme() }
    
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
