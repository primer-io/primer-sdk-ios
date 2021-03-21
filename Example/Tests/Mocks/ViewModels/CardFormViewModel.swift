//
//  CardFormViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

@testable import PrimerSDK

class MockCardFormViewModel: CardFormViewModelProtocol {
    var theme: PrimerTheme {
        return PrimerTheme()
    }
    
    var flow: PrimerSessionFlow {
        return .completeDirectCheckout
    }
    
    func configureView(_ completion: @escaping (Error?) -> Void) {
        return
    }
    
    var cardScannerViewModel: CardScannerViewModelProtocol {
        return MockCardScannerViewModel()
    }
    
    var tokenizeCalled = false
    
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        tokenizeCalled = true
    }
}
