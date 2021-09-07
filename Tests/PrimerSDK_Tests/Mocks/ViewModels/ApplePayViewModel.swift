//
//  ApplePayViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockApplePayViewModel: ApplePayViewModelProtocol {
    var amount: Int?
    
    func tokenize(instrument: PaymentMethod.Details, completion: @escaping (Error?) -> Void) {
        
    }
    
        
    var orderItems: [OrderItem] { return [] }
    
    var clientToken: DecodedClientToken?
    
    var isVaulted: Bool { return false }
    
    var uxMode: UXMode { return .CHECKOUT }
    
    func payWithApple(completion: @escaping (Error?) -> Void) {
        
    }
    
    var applePayConfigId: String? { return "applePayConfigId" }

    var currency: Currency? { return .EUR }

    var merchantIdentifier: String? { "mid" }

    var countryCode: CountryCode? { return .fr }

    var calledTokenize = false

}

#endif
