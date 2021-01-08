//
//  CardFormViewModelTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/01/2021.
//

import XCTest
@testable import PrimerSDK

class CardFormViewModelTests: XCTestCase {
    
    func test_tokenize_calls_tokenizationService_tokenize() throws {
        var onTokenizeSuccessCalled = false
        
        let settings = PrimerSettings(
            amount: 200,
            currency: .EUR,
            clientTokenRequestCallback: { completion in },
            onTokenizeSuccess: { (result, callback) in
                onTokenizeSuccessCalled = true
            },
            theme: PrimerTheme(),
            uxMode: .CHECKOUT,
            applePayEnabled: false,
            customerId: "cid",
            merchantIdentifier: "mid",
            countryCode: .FR
        )
        
        let clientTokenService = MockClientTokenService()
        let tokenizationService = MockTokenizationService()
        let paymentInstrument = PaymentInstrument()
        let cardScannerViewModel = MockCardScannerViewModel()
        
        let viewModel = CardFormViewModel(
            with: settings,
            and: cardScannerViewModel,
            and: tokenizationService,
            and: clientTokenService
        )
        
        viewModel.tokenize(instrument: paymentInstrument, completion: { error in })
        
        XCTAssertEqual(tokenizationService.tokenizeCalled, true)
        XCTAssertEqual(onTokenizeSuccessCalled, true)
    }
    
}
