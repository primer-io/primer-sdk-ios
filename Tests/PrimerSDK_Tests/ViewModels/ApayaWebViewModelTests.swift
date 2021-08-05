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

    func test_onRedirect_calls_setApayaResult() throws {
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        let viewModel = ApayaWebViewModel()
        
        viewModel.onRedirect(with: URL(string: "https://primer.io")!)

        XCTAssertTrue(state.setApayaResultCalled)
    }
}

#endif
