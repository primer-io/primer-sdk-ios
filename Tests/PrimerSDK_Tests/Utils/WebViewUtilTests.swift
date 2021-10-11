//
//  WebViewUtilTests.swift
//  PrimerSDK_Tests
//
//  Created by Carl Eriksson on 06/10/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class WebViewUtilTests: XCTestCase {

    func test_allowed_patterns_return_true() throws {
        let allowedPatterns = [
            WebViewUtil.isPrimerDomain("primer.io"),
            WebViewUtil.isPrimerDomain("app.primer.io"),
            WebViewUtil.isPrimerDomain("livedemostore.primer.io")
        ]
        XCTAssertTrue(allowedPatterns.allSatisfy { $0 == true })
    }
    
    func test_disallowed_patterns_return_false() throws {
        let allowedPatterns = [
            WebViewUtil.isPrimerDomain("rimer.io"),
            WebViewUtil.isPrimerDomain("app.primer.com"),
            WebViewUtil.isPrimerDomain("prymer.io"),
            WebViewUtil.isPrimerDomain("primer.io.carlito"),
            WebViewUtil.isPrimerDomain("primer.i"),
            WebViewUtil.isPrimerDomain("pprimer.io")
        ]
        XCTAssertTrue(allowedPatterns.allSatisfy { $0 == false })
    }
}
