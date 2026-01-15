//
//  NolPayPhoneMetadataServiceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerNolPaySDK)
import PrimerFoundation
import PrimerNolPaySDK
@testable import PrimerSDK
import XCTest

final class NolPayPhoneMetadataServiceTests: XCTestCase {
    var sut: NolPayPhoneMetadataService!
    var mockApiClient: MockPrimerAPIClient!

    let mobileNumber = "+111123123123123"
    let countryCode = "+111"
    let nationalNumber = "123123123123"

    override func setUp() {
        super.setUp()

        let paymentMethod = Mocks.PaymentMethods.nolPaymentMethod
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        mockApiClient = MockPrimerAPIClient()
        sut = NolPayPhoneMetadataService(apiClient: mockApiClient)
    }

    override func tearDown() {
        mockApiClient = nil
        sut = nil

        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    func test_getPhoneMetadata_withNilClientToken_shouldReturnInvalidClientTokenError() {
        // Given
        let exp = expectation(description: " Wait for getPhoneMetadata to complete")
        AppState.current.clientToken = nil

        // When
        sut.getPhoneMetadata(mobileNumber: mobileNumber) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case let .failure(error):
                XCTAssertEqual(error.errorId, "invalid-client-token")
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_getPhoneMetadata_withEmptyMobileNumber_shouldReturnInvalidPhoneNumberError() {
        // Given
        let exp = expectation(description: " Wait for getPhoneMetadata to complete")
        let expectedPhoneError = PrimerValidationError.invalidPhoneNumber(
            message: "Phone number cannot be blank."
        )

        // When
        sut.getPhoneMetadata(mobileNumber: "") { result in
            switch result {
            case let .success((validationStatus, countryCode, mobileNumber)):
                if case let .invalid(errors) = validationStatus {
                    XCTAssertEqual(errors.map(\.errorDescription), [expectedPhoneError].map(\.errorDescription))
                    XCTAssertNil(countryCode)
                    XCTAssertNil(mobileNumber)
                } else {
                    XCTFail("Expected invalid but got \(validationStatus)")
                }

            case let .failure(error):
                XCTFail("Expected success but got failure: \(error)")
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_getPhoneMetadata_withApiClientFailure_shouldReturnExpectedError() {
        // Given
        let exp = expectation(description: " Wait for getPhoneMetadata to complete")
        let expectedErrorCode = "EXPECTED_ERROR_CODE"
        let expectedError = PrimerError.nolError(code: expectedErrorCode, message: "")
        mockApiClient.getPhoneMetadataResult = .failure(expectedError)

        // When
        sut.getPhoneMetadata(mobileNumber: mobileNumber) { result in
            switch result {
            case let .success((validationStatus, countryCode, mobileNumber)):
                XCTFail("Expected failure but got success: \(validationStatus), \(countryCode ?? ""), \(mobileNumber ?? "")")
            case let .failure(error):
                switch error {
                case let .underlyingErrors(errors, _):
                    guard let firstPrimerError = errors.first as? PrimerError else {
                        XCTFail("Expected PrimerError but got \(error)")
                        return
                    }
                    switch firstPrimerError {
                    case let .nolError(code, _, _):
                        XCTAssertEqual(code, expectedErrorCode)
                    default:
                        XCTFail("Expected PrimerError.nolError but got \(firstPrimerError)")
                    }
                default:
                    XCTFail("Expected PrimerError but got \(error)")
                }
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_getPhoneMetadata_withInvalidPhoneNumber_shouldReturnValidationError() {
        // Given
        let exp = expectation(description: " Wait for getPhoneMetadata to complete")
        let expectedError = PrimerValidationError.invalidPhoneNumber(
            message: "Phone number is not valid."
        )
        mockApiClient.getPhoneMetadataResult = .success(.init(isValid: false, countryCode: nil, nationalNumber: nil))

        // When
        sut.getPhoneMetadata(mobileNumber: mobileNumber) { result in
            switch result {
            case let .success((validationStatus, countryCode, mobileNumber)):
                if case let .invalid(errors) = validationStatus {
                    XCTAssertEqual(errors.map(\.errorDescription), [expectedError].map(\.errorDescription))
                    XCTAssertNil(countryCode)
                    XCTAssertNil(mobileNumber)
                } else {
                    XCTFail("Expected invalid but got \(validationStatus)")
                }
            case let .failure(error):
                XCTFail("Expected success but got failure: \(error)")
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_getPhoneMetadata_withValidPhoneNumber_shouldReturnValidStatus() {
        // Given
        let exp = expectation(description: " Wait for getPhoneMetadata to complete")
        mockApiClient.getPhoneMetadataResult = .success(.init(isValid: true, countryCode: countryCode, nationalNumber: nationalNumber))

        // When
        sut.getPhoneMetadata(mobileNumber: mobileNumber) { result in
            switch result {
            case let .success((validationStatus, countryCode, mobileNumber)):
                if case .valid = validationStatus {
                    XCTAssertEqual(countryCode, self.countryCode)
                    XCTAssertEqual(mobileNumber, self.nationalNumber)
                } else {
                    XCTFail("Expected valid but got \(validationStatus)")
                }
            case let .failure(error):
                XCTFail("Expected success but got failure: \(error)")
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }
}
#endif
