//
//  DirectCheckoutViewModelTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/01/2021.
//

import XCTest
@testable import PrimerSDK

class ApplePayViewModelTests: XCTestCase {
    
    func test_tokenize_calls_tokenizationService_tokenize_onTokenizeSuccess() throws {
        
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
        let paymentMethodConfigService = MockPaymentMethodConfigService()
        let paymentInstrument = PaymentInstrument()
        
        let viewModel = ApplePayViewModel(
            with: settings,
            and: clientTokenService,
            and: tokenizationService,
            and: paymentMethodConfigService
        )
        
        viewModel.tokenize(instrument: paymentInstrument, completion: { error in })
        
        XCTAssertEqual(tokenizationService.tokenizeCalled, true)
        XCTAssertEqual(onTokenizeSuccessCalled, true)
    }
    
    func test_tokenize_calls_tokenizationService_passes_error() throws {
        
        var onTokenizeSuccessCalled = false
        var hasError = false
        
        let settings = PrimerSettings(
            amount: 200,
            currency: .EUR,
            clientTokenRequestCallback: { completion in },
            onTokenizeSuccess: { (result, callback) in
                onTokenizeSuccessCalled = true
                callback(PrimerError.CustomerIDNull)
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
        let paymentMethodConfigService = MockPaymentMethodConfigService()
        let paymentInstrument = PaymentInstrument()
        
        let viewModel = ApplePayViewModel(
            with: settings,
            and: clientTokenService,
            and: tokenizationService,
            and: paymentMethodConfigService
        )
        
        viewModel.tokenize(instrument: paymentInstrument, completion: { error in
            if error != nil { hasError = true }
        })
        
        XCTAssertEqual(tokenizationService.tokenizeCalled, true)
        XCTAssertEqual(onTokenizeSuccessCalled, true)
        XCTAssertEqual(hasError, true)
    }
}
