//
//  URLSessionStackTests.swift
//  Debug App Tests
//
//  Created by Boris on 27.7.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

private struct DummyEndpoint: Endpoint {
    var baseURL: String?
    var port: Int? = nil
    var path: String = ""
    var method: PrimerSDK.HTTPMethod = .get
    var headers: [String : String]? = nil
    var queryParameters: [String : String]? = nil
    var body: Data? = nil
    var shouldParseResponseBody: Bool = false
    
    init(baseURL: String?, path: String = "", queryParameters: [String: String]? = nil) {
        self.baseURL = baseURL
        self.path = path
        self.queryParameters = queryParameters
    }
}

final class URLSessionStackTests: XCTestCase {
    
    var sut: URLSessionStack = URLSessionStack()
    
    // Test for base URL and path
    func testBaseURLWithPath() {
        let endpoint = DummyEndpoint(baseURL: "https://www.example.com", path: "/test")
        let url = sut.url(for: endpoint)
        XCTAssertEqual(url?.absoluteString, "https://www.example.com/test")
    }
    
    // Test for query parameters
    func testQueryParameters() {
        let endpoint = DummyEndpoint(baseURL: "https://www.example.com", queryParameters: ["key1": "value1", "key2": "value2"])
        let url = sut.url(for: endpoint)
        XCTAssertTrue(url?.absoluteString.contains("key1=value1") == true)
        XCTAssertTrue(url?.absoluteString.contains("key2=value2") == true)
    }
    
    // Test for nil base URL
    func testNilBaseURL() {
        let endpoint = DummyEndpoint(baseURL: nil)
        let url = sut.url(for: endpoint)
        XCTAssertNil(url)
    }
    
    // Test for empty path
    func testEmptyPath() {
        let endpoint = DummyEndpoint(baseURL: "https://www.example.com", path: "")
        let url = sut.url(for: endpoint)
        XCTAssertEqual(url?.absoluteString, "https://www.example.com")
    }
    
    // Test for query parameters with empty path
    func testQueryParametersWithEmptyPath() {
        let endpoint = DummyEndpoint(baseURL: "https://www.example.com", path: "", queryParameters: ["key1": "value1", "key2": "value2"])
        let url = sut.url(for: endpoint)
        XCTAssertTrue(url?.absoluteString.contains("key1=value1") == true)
        XCTAssertTrue(url?.absoluteString.contains("key2=value2") == true)
    }
    
}
#endif
