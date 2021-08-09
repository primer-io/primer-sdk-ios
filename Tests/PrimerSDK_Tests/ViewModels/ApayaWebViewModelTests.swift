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

    func test_onDismiss_calls_setApayaResult_if_result() throws {
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        let viewModel = ApayaWebViewModel()
        
        viewModel.onRedirect(with: URL(string: "https://primer.io")!)
        viewModel.onDismiss()

        XCTAssertTrue(state.setApayaResultCalled)
    }
    
    func test_onDismiss_does_not_call_setApayaResult_if_result_nil() throws {
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        let viewModel = ApayaWebViewModel()
        
        viewModel.onDismiss()

        XCTAssertFalse(state.setApayaResultCalled)
    }
}

#endif
