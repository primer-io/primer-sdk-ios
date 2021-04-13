//
//  DirectCheckoutViewModelTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/01/2021.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class ApplePayViewModelTests: XCTestCase {

    func test_tokenize_calls_tokenizationService_tokenize_onTokenizeSuccess() throws {
        let tokenizationService = MockTokenizationService()
        let paymentInstrument = PaymentInstrument()

        MockLocator.registerDependencies()
        DependencyContainer.register(tokenizationService as TokenizationServiceProtocol)

        let viewModel = ApplePayViewModel()

        viewModel.tokenize(instrument: paymentInstrument, completion: { _ in })

        XCTAssertEqual(tokenizationService.tokenizeCalled, true)
    }

    func test_tokenize_calls_tokenizationService_passes_error() throws {
        let expectation = XCTestExpectation(description: "Tokenization | Error")
        
        let tokenizationService = MockTokenizationService()
        let paymentInstrument = PaymentInstrument()

        MockLocator.registerDependencies()
        DependencyContainer.register(tokenizationService as TokenizationServiceProtocol)

        let viewModel = ApplePayViewModel()

        viewModel.tokenize(instrument: paymentInstrument) { _ in
            XCTAssertEqual(tokenizationService.tokenizeCalled, true)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
    }
}

#endif
