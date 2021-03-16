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
        let paymentInstrument = PaymentInstrument()
        
        MockLocator.registerDependencies()
        DependencyContainer.register(tokenizationService as TokenizationServiceProtocol)
        
        let viewModel = CardFormViewModel()
        
        viewModel.tokenize(instrument: paymentInstrument, completion: { error in })
        
        XCTAssertEqual(tokenizationService.tokenizeCalled, true)
    }
    
}
