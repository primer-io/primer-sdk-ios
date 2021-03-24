//
//  ApplePayViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockApplePayViewModel: ApplePayViewModelProtocol {
    var amount: Int { return 200 }
    
    var applePayConfigId: String? { return "applePayConfigId" }
    
    var currency: Currency { return .EUR }
    
    var merchantIdentifier: String? { "mid" }
    
    var countryCode: CountryCode? { return .fr }
    
    var calledTokenize = false
    
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        calledTokenize = true
    }
}

#endif
