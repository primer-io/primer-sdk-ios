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
        let tokenizationService = MockTokenizationService()
        let serviceLocator = MockServiceLocator(tokenizationService: tokenizationService)
        let paymentInstrument = PaymentInstrument()
        let context = MockCheckoutContext(serviceLocator: serviceLocator)
        
        let viewModel = CardFormViewModel(context: context)
        
        viewModel.tokenize(instrument: paymentInstrument, completion: { error in })
        
        XCTAssertEqual(tokenizationService.tokenizeCalled, true)
    }
    
}
