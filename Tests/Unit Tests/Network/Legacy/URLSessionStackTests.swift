//
//  URLSessionStackTests.swift
//  Debug App Tests
//
//  Created by Boris on 27.7.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

private struct DummyEndpoint: Endpoint {

    var timeout: TimeInterval?
    var baseURL: String?
    var port: Int?
    var path: String = ""
    var method: PrimerSDK.HTTPMethod = .get
    var headers: [String: String]?
    var queryParameters: [String: String]?
    var body: Data?
    var shouldParseResponseBody: Bool = false

    init(baseURL: String?, path: String = "", queryParameters: [String: String]? = nil) {
        self.baseURL = baseURL
        self.path = path
        self.queryParameters = queryParameters
    }
}

final class URLSessionStackTests: XCTestCase {

    var sut: URLSessionStack!

    override func setUp() {
        super.setUp()
        sut = URLSessionStack()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

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
        XCTAssertTrue(url?.absoluteString.contains("key1=value1"))
        XCTAssertTrue(url?.absoluteString.contains("key2=value2"))
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
        XCTAssertTrue(url?.absoluteString.contains("key1=value1"))
        XCTAssertTrue(url?.absoluteString.contains("key2=value2"))
    }

    // Test that /sdk-logs and polling endpoints are omitted from network analytics reporting
    func testAnalyticsReportingForOmitted() {
        // Test endpoints that shouldn't cause a network event to be reported
        XCTAssertFalse(sut.shouldReportNetworkEvents(for: PrimerAPI.poll(clientToken: nil, url: "")))
        XCTAssertFalse(sut.shouldReportNetworkEvents(for: PrimerAPI.sendAnalyticsEvents(clientToken: nil, url: Analytics.Service.defaultSdkLogsUrl, body: nil)))
        XCTAssertFalse(sut.shouldReportNetworkEvents(for: PrimerAPI.sendAnalyticsEvents(clientToken: nil, url: URL(string: "https://anything-that-ends.with/sdk-logs")!, body: nil)))
        XCTAssertFalse(sut.shouldReportNetworkEvents(for: PrimerAPI.sendAnalyticsEvents(clientToken: nil, url: URL(string: "https://anything-that-ends.with/checkout/track")!, body: nil)))

        // Test selection of endpoints that should cause a network event to be reported
        XCTAssertTrue(sut.shouldReportNetworkEvents(for: PrimerAPI.createPayment(clientToken: mockClientToken, paymentRequest: .init(token: ""))))
        XCTAssertTrue(sut.shouldReportNetworkEvents(for: PrimerAPI.fetchConfiguration(clientToken: mockClientToken, requestParameters: .init(skipPaymentMethodTypes: nil, requestDisplayMetadata: nil))))
        XCTAssertTrue(sut.shouldReportNetworkEvents(for: PrimerAPI.fetchVaultedPaymentMethods(clientToken: mockClientToken)))
        let paymentInstrument = CardPaymentInstrument(number: "", cvv: "", expirationMonth: "", expirationYear: "")
        XCTAssertTrue(sut.shouldReportNetworkEvents(for: PrimerAPI.tokenizePaymentMethod(clientToken: mockClientToken, tokenizationRequestBody: .init(paymentInstrument: paymentInstrument))))
        let klarnaCreatePaymentSession = Request.Body.Klarna.CreatePaymentSession(paymentMethodConfigId: "", sessionType: .oneOffPayment, description: nil, redirectUrl: nil, totalAmount: nil, orderItems: nil, billingAddress: nil, shippingAddress: nil)
        XCTAssertTrue(sut.shouldReportNetworkEvents(for: PrimerAPI.createKlarnaPaymentSession(clientToken: mockClientToken, klarnaCreatePaymentSessionAPIRequest: klarnaCreatePaymentSession)))
    }

}
