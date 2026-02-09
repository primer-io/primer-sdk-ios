//
//  HeadlessRepositoryAnalyticsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - URL Extraction Tests

@available(iOS 15.0, *)
final class ExtractURLTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testExtractURL_FromString_WithHttps_ReturnsURL() {
        // When
        let result = repository.extractURL(from: "https://example.com/payment")

        // Then
        XCTAssertEqual(result, "https://example.com/payment")
    }

    func testExtractURL_FromString_WithHttp_ReturnsURL() {
        // When
        let result = repository.extractURL(from: "http://example.com/payment")

        // Then
        XCTAssertEqual(result, "http://example.com/payment")
    }

    func testExtractURL_FromString_WithoutScheme_ReturnsNil() {
        // When
        let result = repository.extractURL(from: "example.com/payment")

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_FromURL_ReturnsAbsoluteString() {
        // Given
        let url = URL(string: "https://example.com/payment")!

        // When
        let result = repository.extractURL(from: url)

        // Then
        XCTAssertEqual(result, "https://example.com/payment")
    }

    func testExtractURL_FromInteger_ReturnsNil() {
        // When
        let result = repository.extractURL(from: 12345)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_FromEmptyString_ReturnsNil() {
        // When
        let result = repository.extractURL(from: "")

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_FromNonURLString_ReturnsNil() {
        // When
        let result = repository.extractURL(from: "not a url at all")

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_FromDictionary_ReturnsNil() {
        // When
        let result = repository.extractURL(from: ["key": "value"])

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_FromArray_ReturnsNil() {
        // When
        let result = repository.extractURL(from: ["https://example.com"])

        // Then
        XCTAssertNil(result)
    }
}

// MARK: - Is Likely URL Tests

@available(iOS 15.0, *)
final class IsLikelyURLTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testIsLikelyURL_WithHttps_ReturnsTrue() {
        // When
        let result = repository.isLikelyURL("https://example.com")

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithHttp_ReturnsTrue() {
        // When
        let result = repository.isLikelyURL("http://example.com")

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithHttpsUppercase_ReturnsTrue() {
        // When
        let result = repository.isLikelyURL("HTTPS://example.com")

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithHttpUppercase_ReturnsTrue() {
        // When
        let result = repository.isLikelyURL("HTTP://example.com")

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithMixedCaseHttps_ReturnsTrue() {
        // When
        let result = repository.isLikelyURL("HtTpS://example.com")

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithoutScheme_ReturnsFalse() {
        // When
        let result = repository.isLikelyURL("example.com")

        // Then
        XCTAssertFalse(result)
    }

    func testIsLikelyURL_WithFtpScheme_ReturnsFalse() {
        // When
        let result = repository.isLikelyURL("ftp://example.com")

        // Then
        XCTAssertFalse(result)
    }

    func testIsLikelyURL_WithFileScheme_ReturnsFalse() {
        // When
        let result = repository.isLikelyURL("file:///path/to/file")

        // Then
        XCTAssertFalse(result)
    }

    func testIsLikelyURL_WithCustomScheme_ReturnsFalse() {
        // When
        let result = repository.isLikelyURL("myapp://payment")

        // Then
        XCTAssertFalse(result)
    }

    func testIsLikelyURL_WithEmptyString_ReturnsFalse() {
        // When
        let result = repository.isLikelyURL("")

        // Then
        XCTAssertFalse(result)
    }

    func testIsLikelyURL_WithWhitespace_ReturnsFalse() {
        // When
        let result = repository.isLikelyURL("   ")

        // Then
        XCTAssertFalse(result)
    }

    func testIsLikelyURL_WithHttpInMiddle_ReturnsFalse() {
        // When
        let result = repository.isLikelyURL("text containing https://example.com")

        // Then
        XCTAssertFalse(result)
    }

    func testIsLikelyURL_WithHttpsWithQuery_ReturnsTrue() {
        // When
        let result = repository.isLikelyURL("https://example.com/path?query=value&other=123")

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithHttpsWithFragment_ReturnsTrue() {
        // When
        let result = repository.isLikelyURL("https://example.com/path#section")

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithHttpsWithPort_ReturnsTrue() {
        // When
        let result = repository.isLikelyURL("https://example.com:8080/path")

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithHttpsLocalhost_ReturnsTrue() {
        // When
        let result = repository.isLikelyURL("https://localhost:3000")

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithHttpsIPAddress_ReturnsTrue() {
        // When
        let result = repository.isLikelyURL("https://192.168.1.1/payment")

        // Then
        XCTAssertTrue(result)
    }
}

// MARK: - URL Extraction Edge Cases Tests

@available(iOS 15.0, *)
final class URLExtractionEdgeCasesTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testExtractURL_FromURLWithQueryParams_ReturnsFullURL() {
        // Given
        let url = URL(string: "https://example.com/payment?token=abc123&redirect=true")!

        // When
        let result = repository.extractURL(from: url)

        // Then
        XCTAssertEqual(result, "https://example.com/payment?token=abc123&redirect=true")
    }

    func testExtractURL_FromURLWithFragment_ReturnsFullURL() {
        // Given
        let url = URL(string: "https://example.com/payment#success")!

        // When
        let result = repository.extractURL(from: url)

        // Then
        XCTAssertEqual(result, "https://example.com/payment#success")
    }

    func testExtractURL_FromURLWithPort_ReturnsFullURL() {
        // Given
        let url = URL(string: "https://example.com:8443/payment")!

        // When
        let result = repository.extractURL(from: url)

        // Then
        XCTAssertEqual(result, "https://example.com:8443/payment")
    }

    func testExtractURL_FromURLWithEncodedCharacters_ReturnsFullURL() {
        // Given
        let url = URL(string: "https://example.com/payment?name=John%20Doe")!

        // When
        let result = repository.extractURL(from: url)

        // Then
        XCTAssertEqual(result, "https://example.com/payment?name=John%20Doe")
    }

    func testExtractURL_FromStringWithQueryParams_ReturnsString() {
        // When
        let result = repository.extractURL(from: "https://example.com/callback?status=success")

        // Then
        XCTAssertEqual(result, "https://example.com/callback?status=success")
    }

    func testExtractURL_FromStringWithUnicode_ReturnsNilIfInvalid() {
        // When - String with unicode that's not a valid URL prefix
        let result = repository.extractURL(from: "日本語テスト")

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_FromBool_ReturnsNil() {
        // When
        let result = repository.extractURL(from: true)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_FromDouble_ReturnsNil() {
        // When
        let result = repository.extractURL(from: 123.456)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_FromNSNull_ReturnsNil() {
        // When
        let result = repository.extractURL(from: NSNull())

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_FromOptionalNil_ReturnsNil() {
        // Given
        let optionalString: String? = nil

        // When
        let result = repository.extractURL(from: optionalString as Any)

        // Then
        XCTAssertNil(result)
    }

    func testIsLikelyURL_WithDataURL_ReturnsFalse() {
        // When
        let result = repository.isLikelyURL("data:text/html,<h1>Hello</h1>")

        // Then
        XCTAssertFalse(result)
    }

    func testIsLikelyURL_WithJavascriptURL_ReturnsFalse() {
        // When
        let result = repository.isLikelyURL("javascript:alert('test')")

        // Then
        XCTAssertFalse(result)
    }

    func testIsLikelyURL_WithMailtoURL_ReturnsFalse() {
        // When
        let result = repository.isLikelyURL("mailto:test@example.com")

        // Then
        XCTAssertFalse(result)
    }

    func testIsLikelyURL_WithTelURL_ReturnsFalse() {
        // When
        let result = repository.isLikelyURL("tel:+1234567890")

        // Then
        XCTAssertFalse(result)
    }
}
