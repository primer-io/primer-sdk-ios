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
            WebViewUtil.allowedHostsContain("primer.io"),
            WebViewUtil.allowedHostsContain("app.primer.io"),
            WebViewUtil.allowedHostsContain("livedemostore.primer.io")
        ]
        XCTAssertTrue(allowedPatterns.allSatisfy { $0 })
    }

    func test_disallowed_patterns_return_false() throws {
        let allowedPatterns = [
            WebViewUtil.allowedHostsContain("rimer.io"),
            WebViewUtil.allowedHostsContain("app.primer.com"),
            WebViewUtil.allowedHostsContain("prymer.io"),
            WebViewUtil.allowedHostsContain("primer.io.carlito"),
            WebViewUtil.allowedHostsContain("primer.i"),
            WebViewUtil.allowedHostsContain("pprimer.io")
        ]
        XCTAssertTrue(allowedPatterns.allSatisfy { $0  })
    }
}
