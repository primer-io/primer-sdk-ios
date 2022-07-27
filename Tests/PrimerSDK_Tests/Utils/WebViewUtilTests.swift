//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
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
        XCTAssertTrue(allowedPatterns.allSatisfy { $0 == true })
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
        XCTAssertTrue(allowedPatterns.allSatisfy { $0 == false })
    }
}
