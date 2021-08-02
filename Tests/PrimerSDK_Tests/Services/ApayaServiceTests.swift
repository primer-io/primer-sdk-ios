//
//  ApayaServiceTests.swift
//  PrimerSDK_Tests
//
//  Created by Carl Eriksson on 01/08/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class ApayaServiceTests: XCTestCase {

    // MARK: createPaymentSession - Failure due to incomplete Primer initialization
    func test_create_apaya_payment_session_without_session_type() throws {
        let expectation = XCTestExpectation(description: "Create Apaya payment session | Failure: no client token")
        let state = MockAppState()
        state.decodedClientToken = nil
        MockLocator.registerDependencies()
        DependencyContainer.register(state as AppStateProtocol)

        let service = ApayaService()
        service.createPaymentSession { (result) in
            switch result {
            case .failure(let err):
                if let apayaErr = err as? ApayaException,
                   case ApayaException.noToken = apayaErr
                {
                    XCTAssert(true)
                } else {
                    XCTAssert(false, "Test should have failed with error 'noToken' but failed with: \(err)")
                }
            case .success(let urlString):
                XCTAssert(false, "Test should have failed with error 'noToken' but succeeded with url: \(urlString)")

            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: createPaymentSession - Success
    func test_create_apaya_payment_session_success() throws {
        let expectation = XCTestExpectation(description: "Create Apaya payment session | Success")
        MockLocator.registerDependencies()

        let service = ApayaService()
        service.createPaymentSession { (result) in
            switch result {
            case .failure(let err):
                XCTAssert(false, "Test should succeeded, but failed with \(err)")
            case .success:
                XCTAssert(true)

            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}

#endif

