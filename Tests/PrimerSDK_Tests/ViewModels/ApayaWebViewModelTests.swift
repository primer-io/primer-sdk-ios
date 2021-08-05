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

    func test_onRedirect_calls_setApayaResult() throws {
        let state = MockAppState()
        MockLocator.registerDependencies()
        DependencyContainer.register(state as AppStateProtocol)

        let viewModel = ApayaWebViewModel()
        
        viewModel.onRedirect(with: URL(string: "https://primer.io")!)

        XCTAssertTrue(state.setApayaResultCalled)
    }
}

#endif
