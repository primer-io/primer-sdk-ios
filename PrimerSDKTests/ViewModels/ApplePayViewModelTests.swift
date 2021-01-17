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
        let tokenizationService = MockTokenizationService()
        let paymentInstrument = PaymentInstrument()
        let serviceLocator = MockServiceLocator(tokenizationService: tokenizationService)
        let context = MockCheckoutContext(serviceLocator: serviceLocator)
        
        let viewModel = ApplePayViewModel(context: context)
        
        viewModel.tokenize(instrument: paymentInstrument, completion: { error in })
        
        XCTAssertEqual(tokenizationService.tokenizeCalled, true)
    }
    
    func test_tokenize_calls_tokenizationService_passes_error() throws {
        let tokenizationService = MockTokenizationService()
        let paymentInstrument = PaymentInstrument()
        let serviceLocator = MockServiceLocator(tokenizationService: tokenizationService)
        let context = MockCheckoutContext(serviceLocator: serviceLocator)
        
        let viewModel = ApplePayViewModel(context: context)
        
        viewModel.tokenize(instrument: paymentInstrument) { error in }
        
        XCTAssertEqual(tokenizationService.tokenizeCalled, true)
    }
}
