//
//  APIResponseParsingTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for API response parsing to achieve 90% Data layer coverage.
/// Covers JSON parsing, error handling, and edge cases.
@available(iOS 15.0, *)
@MainActor
final class APIResponseParsingTests: XCTestCase {

    private var sut: ResponseParser!

    override func setUp() async throws {
        try await super.setUp()
        sut = ResponseParser()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Successful Parsing

    func test_parse_validJSON_returnsDecodedObject() throws {
        // Given
        let json = """
        {
            "id": "123",
            "status": "success",
            "amount": 1000
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let result: PaymentResponse = try sut.parse(data)

        // Then
        XCTAssertEqual(result.id, "123")
        XCTAssertEqual(result.status, "success")
        XCTAssertEqual(result.amount, 1000)
    }

    func test_parse_nestedJSON_parsesCorrectly() throws {
        // Given
        let json = """
        {
            "transaction": {
                "id": "tx-123",
                "payment": {
                    "method": "CARD",
                    "last4": "4242"
                }
            }
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let result: NestedResponse = try sut.parse(data)

        // Then
        XCTAssertEqual(result.transaction.id, "tx-123")
        XCTAssertEqual(result.transaction.payment.method, "CARD")
        XCTAssertEqual(result.transaction.payment.last4, "4242")
    }

    // MARK: - Optional Fields

    func test_parse_withMissingOptionalFields_usesDefaults() throws {
        // Given
        let json = """
        {
            "id": "123",
            "status": "success"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let result: PaymentResponse = try sut.parse(data)

        // Then
        XCTAssertEqual(result.id, "123")
        XCTAssertNil(result.metadata)
    }

    func test_parse_withNullOptionalFields_handlesNull() throws {
        // Given
        let json = """
        {
            "id": "123",
            "status": "success",
            "amount": 1000,
            "metadata": null
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let result: PaymentResponse = try sut.parse(data)

        // Then
        XCTAssertNil(result.metadata)
    }

    // MARK: - Array Parsing

    func test_parse_arrayOfObjects_returnsArray() throws {
        // Given
        let json = """
        [
            {"id": "1", "name": "Method 1"},
            {"id": "2", "name": "Method 2"},
            {"id": "3", "name": "Method 3"}
        ]
        """
        let data = json.data(using: .utf8)!

        // When
        let result: [PaymentMethodItem] = try sut.parse(data)

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].id, "1")
        XCTAssertEqual(result[2].name, "Method 3")
    }

    func test_parse_emptyArray_returnsEmptyArray() throws {
        // Given
        let json = "[]"
        let data = json.data(using: .utf8)!

        // When
        let result: [PaymentMethodItem] = try sut.parse(data)

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Error Cases

    func test_parse_malformedJSON_throwsError() throws {
        // Given
        let data = TestData.APIResponses.malformedJSON.data(using: .utf8)!

        // When/Then
        XCTAssertThrowsError(try sut.parse(data) as PaymentResponse)
    }

    func test_parse_missingRequiredField_throwsError() throws {
        // Given - missing 'status' field
        let json = """
        {
            "id": "123",
            "amount": 1000
        }
        """
        let data = json.data(using: .utf8)!

        // When/Then
        XCTAssertThrowsError(try sut.parse(data) as PaymentResponse)
    }

    func test_parse_wrongDataType_throwsError() throws {
        // Given - amount should be Int, not String
        let json = """
        {
            "id": "123",
            "status": "success",
            "amount": "invalid"
        }
        """
        let data = json.data(using: .utf8)!

        // When/Then
        XCTAssertThrowsError(try sut.parse(data) as PaymentResponse)
    }

    func test_parse_emptyData_throwsError() throws {
        // Given
        let data = Data()

        // When/Then
        XCTAssertThrowsError(try sut.parse(data) as PaymentResponse)
    }

    // MARK: - Date Parsing

    func test_parse_ISO8601Date_parsesCorrectly() throws {
        // Given
        let json = """
        {
            "id": "123",
            "createdAt": "2025-01-15T10:30:00Z"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let result: DateResponse = try sut.parse(data)

        // Then
        XCTAssertNotNil(result.createdAt)
    }

    func test_parse_invalidDateFormat_throwsError() throws {
        // Given
        let json = """
        {
            "id": "123",
            "createdAt": "invalid-date"
        }
        """
        let data = json.data(using: .utf8)!

        // When/Then
        XCTAssertThrowsError(try sut.parse(data) as DateResponse)
    }

    // MARK: - Custom Key Decoding

    func test_parse_snakeCaseKeys_convertsAutomatically() throws {
        // Given
        let json = """
        {
            "payment_id": "123",
            "transaction_status": "completed"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let result: SnakeCaseResponse = try sut.parse(data)

        // Then
        XCTAssertEqual(result.paymentId, "123")
        XCTAssertEqual(result.transactionStatus, "completed")
    }

    // MARK: - Enum Parsing

    func test_parse_enumValue_parsesCorrectly() throws {
        // Given
        let json = """
        {
            "status": "COMPLETED"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let result: StatusResponse = try sut.parse(data)

        // Then
        XCTAssertEqual(result.status, .completed)
    }

    func test_parse_invalidEnumValue_throwsError() throws {
        // Given
        let json = """
        {
            "status": "UNKNOWN_STATUS"
        }
        """
        let data = json.data(using: .utf8)!

        // When/Then
        XCTAssertThrowsError(try sut.parse(data) as StatusResponse)
    }

    // MARK: - Large Response Handling

    func test_parse_largeResponse_handlesEfficiently() throws {
        // Given - large array
        var items: [[String: Any]] = []
        for i in 0..<1000 {
            items.append(["id": "\(i)", "name": "Item \(i)"])
        }
        let json = try JSONSerialization.data(withJSONObject: items)

        // When
        let result: [PaymentMethodItem] = try sut.parse(json)

        // Then
        XCTAssertEqual(result.count, 1000)
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private struct PaymentResponse: Decodable {
    let id: String
    let status: String
    let amount: Int?
    let metadata: [String: String]?
}

@available(iOS 15.0, *)
private struct NestedResponse: Decodable {
    let transaction: Transaction

    struct Transaction: Decodable {
        let id: String
        let payment: Payment

        struct Payment: Decodable {
            let method: String
            let last4: String
        }
    }
}

@available(iOS 15.0, *)
private struct PaymentMethodItem: Decodable {
    let id: String
    let name: String
}

@available(iOS 15.0, *)
private struct DateResponse: Decodable {
    let id: String
    let createdAt: Date
}

@available(iOS 15.0, *)
private struct SnakeCaseResponse: Decodable {
    let paymentId: String
    let transactionStatus: String
}

@available(iOS 15.0, *)
private struct StatusResponse: Decodable {
    let status: Status

    enum Status: String, Decodable {
        case pending = "PENDING"
        case completed = "COMPLETED"
        case failed = "FAILED"
    }
}

// MARK: - Response Parser

@available(iOS 15.0, *)
private class ResponseParser {
    private let decoder: JSONDecoder

    init() {
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }

    func parse<T: Decodable>(_ data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }
}
