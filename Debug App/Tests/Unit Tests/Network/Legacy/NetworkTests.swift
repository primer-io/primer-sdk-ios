//
//  NetworkTests.swift
//  Debug App Tests
//
//  Created by Alexandra Lovin on 09.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import Debug_App
final class NetworkTests: XCTestCase {

    func test_http_headers_new_workflows() {
        XCTAssertNil(URL.requestSessionHTTPHeaders(useNewWorkflows: false))
        XCTAssertEqual(URL.requestSessionHTTPHeaders(useNewWorkflows: true), ["Legacy-Workflows": "false"])
    }
}
