//
//  ComponentsBillingAddressBridgeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@_spi(PrimerInternal) @testable import PrimerSDK

@available(iOS 15.0, *)
final class ComponentsBillingAddressBridgeTests: XCTestCase {

    private var sut: ComponentsBillingAddressBridge!
    private var dispatchedAddresses: [ClientSession.Address] = []
    private var dispatchError: Error?

    override func setUp() async throws {
        try await super.setUp()
        dispatchedAddresses = []
        dispatchError = nil
        sut = ComponentsBillingAddressBridge { [self] address in
            dispatchedAddresses.append(address)
            if let error = dispatchError {
                throw error
            }
        }
    }

    override func tearDown() async throws {
        sut = nil
        dispatchedAddresses = []
        dispatchError = nil
        try await super.tearDown()
    }

    // MARK: - Validation Tests

    func test_setBillingAddress_allFieldsBlank_throwsInvalidRawData() async {
        // Given
        let address = PrimerAddress(
            firstName: nil, lastName: nil,
            addressLine1: nil, addressLine2: nil,
            postalCode: nil, city: nil,
            state: nil, countryCode: nil
        )

        // When / Then
        await assertThrowsInvalidRawData {
            try await self.sut.setBillingAddress(address)
        }
        XCTAssertTrue(dispatchedAddresses.isEmpty)
    }

    func test_setBillingAddress_allFieldsEmptyStrings_throwsInvalidRawData() async {
        // Given
        let address = PrimerAddress(
            firstName: "", lastName: "",
            addressLine1: "", addressLine2: "",
            postalCode: "", city: "",
            state: "", countryCode: ""
        )

        // When / Then
        await assertThrowsInvalidRawData {
            try await self.sut.setBillingAddress(address)
        }
        XCTAssertTrue(dispatchedAddresses.isEmpty)
    }

    func test_setBillingAddress_invalidCountryCode_throwsInvalidRawData() async {
        // Given
        let address = PrimerAddress(
            firstName: "Onur", lastName: nil,
            addressLine1: nil, addressLine2: nil,
            postalCode: nil, city: nil,
            state: nil, countryCode: "USA"
        )

        // When / Then
        await assertThrowsInvalidRawData {
            try await self.sut.setBillingAddress(address)
        }
        XCTAssertTrue(dispatchedAddresses.isEmpty)
    }

    func test_setBillingAddress_emptyCountryCodeWithOtherFields_dispatchesAction() async throws {
        // Given
        let address = PrimerAddress(
            firstName: "Onur", lastName: nil,
            addressLine1: nil, addressLine2: nil,
            postalCode: nil, city: nil,
            state: nil, countryCode: ""
        )

        // When
        try await sut.setBillingAddress(address)

        // Then
        XCTAssertEqual(dispatchedAddresses.count, 1)
        XCTAssertNil(dispatchedAddresses.first?.countryCode)
    }

    // MARK: - Dispatch Tests

    func test_setBillingAddress_validAddress_dispatchesActionWithMappedFields() async throws {
        // Given
        let address = PrimerAddress(
            firstName: "Onur", lastName: "Var",
            addressLine1: "1 Test St", addressLine2: "Apt 2",
            postalCode: "EC1A 1AA", city: "London",
            state: "Greater London", countryCode: "GB"
        )

        // When
        try await sut.setBillingAddress(address)

        // Then
        XCTAssertEqual(dispatchedAddresses.count, 1)
        let dispatched = try XCTUnwrap(dispatchedAddresses.first)
        XCTAssertEqual(dispatched.firstName, "Onur")
        XCTAssertEqual(dispatched.lastName, "Var")
        XCTAssertEqual(dispatched.addressLine1, "1 Test St")
        XCTAssertEqual(dispatched.addressLine2, "Apt 2")
        XCTAssertEqual(dispatched.city, "London")
        XCTAssertEqual(dispatched.postalCode, "EC1A 1AA")
        XCTAssertEqual(dispatched.state, "Greater London")
        XCTAssertEqual(dispatched.countryCode, .gb)
    }

    func test_setBillingAddress_singleField_dispatchesAction() async throws {
        // Given
        let address = PrimerAddress(
            firstName: "Onur", lastName: nil,
            addressLine1: nil, addressLine2: nil,
            postalCode: nil, city: nil,
            state: nil, countryCode: nil
        )

        // When
        try await sut.setBillingAddress(address)

        // Then
        XCTAssertEqual(dispatchedAddresses.count, 1)
        XCTAssertEqual(dispatchedAddresses.first?.firstName, "Onur")
    }

    func test_setBillingAddress_dispatchFails_propagatesError() async {
        // Given
        let expected = NSError(domain: "test", code: 42)
        dispatchError = expected
        let address = PrimerAddress(
            firstName: "Onur", lastName: nil,
            addressLine1: nil, addressLine2: nil,
            postalCode: nil, city: nil,
            state: nil, countryCode: nil
        )

        // When / Then
        do {
            try await sut.setBillingAddress(address)
            XCTFail("expected dispatch error")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "test")
            XCTAssertEqual(error.code, 42)
        }
    }

    // MARK: - Helpers

    private func assertThrowsInvalidRawData(
        _ block: @escaping () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            try await block()
            XCTFail("expected PrimerValidationError.invalidRawData", file: file, line: line)
        } catch let error as PrimerValidationError {
            switch error {
            case .invalidRawData:
                break
            default:
                XCTFail("expected .invalidRawData, got \(error)", file: file, line: line)
            }
        } catch {
            XCTFail("expected PrimerValidationError.invalidRawData, got \(error)", file: file, line: line)
        }
    }
}
