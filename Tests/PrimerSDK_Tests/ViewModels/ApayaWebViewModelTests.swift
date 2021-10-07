//
//  ApayaWebViewModelTests.swift
//  PrimerSDK_Tests
//
//  Created by Carl Eriksson on 05/08/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class ApayaWebViewModelTests: XCTestCase {
    
    override func setUp() {
        MockLocator.registerDependencies()
    }

    func test_apaya_tokenization() throws {
        let expectation = XCTestExpectation(description: "Apaya tokenization")
        
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        
        let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
        let mockTokenizationService = tokenizationService as! MockTokenizationService
        mockTokenizationService.paymentInstrumentType = PaymentMethodConfigType.apaya.rawValue
        mockTokenizationService.tokenType = TokenType.multiUse.rawValue

        Primer.shared.showPaymentMethod(.apaya, withIntent: .vault, on: UIViewController())
        let viewModel = ApayaWebViewModel()
        viewModel.onCompletion = { result in
            switch result {
            case .success(let token):
                if token.paymentInstrumentType != .apayaToken {
                    XCTFail("\(token.paymentInstrumentType) is not an Apaya token")
                }
                
                if token.tokenType != .multiUse {
                    XCTFail("\(token.tokenType) is not a multi use token")
                }
            default:
                XCTFail("Should be tokenized successfully")
            }

            expectation.fulfill()
        }
        
        viewModel.onRedirect(with: URL(string: "https://primer.io?success=1&status=success&HashedIdentifier=id&MX=12&MCC=mcc&MNC=mnc")!)

        wait(for: [expectation], timeout: 5)
    }

}

#endif
