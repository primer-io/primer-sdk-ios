//
//  NolPayPhoneMetadataServiceTests.swift
//  Debug App Tests
//
//  Created by Boris on 27.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerNolPaySDK)
import XCTest
@testable import PrimerSDK
import PrimerNolPaySDK

final class NolPayPhoneMetadataServiceTests: XCTestCase {

    typealias ValidationResult = Result<(PrimerValidationStatus, String?, String?), PrimerError>

    func testGetPhoneMetadata() {
        let mockService = MockPhoneMetadataService()
        let expectedResult = ValidationResult.success((.valid, "+123", "1234567890"))

        mockService.resultToReturn = expectedResult

        let expectation = self.expectation(description: "PhoneMetadata")

        mockService.getPhoneMetadata(mobileNumber: "1234567890") { result in
            switch result {

            case let .success((validationStatus, countryCode, mobileNumber)):
                switch validationStatus {
                case .valid:
                    break
                default:
                    XCTFail()
                }
                XCTAssert(countryCode == "+123")
                XCTAssert(mobileNumber == "1234567890")
                expectation.fulfill()
            case .failure:
                XCTFail("Expected succes but got failure")
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testGetPhoneMetadata_InvalidPhoneNumber() {
        let mockService = MockPhoneMetadataService()
        let validationError = PrimerValidationError.invalidPhoneNumber(message: "Invalid", userInfo: [:], diagnosticsId: "1")
        let expectedResult = ValidationResult.success((.invalid(errors: [validationError]), nil, nil))
        mockService.resultToReturn = expectedResult

        let expectation = self.expectation(description: "PhoneMetadata")

        mockService.getPhoneMetadata(mobileNumber: "invalid") { result in
            switch result {
            case let .success((validationStatus, _, _)):
                switch validationStatus {
                case .invalid(let errors):
                    XCTAssertEqual(errors.map { $0.errorId }, [validationError].map { $0.errorId })
                default:
                    XCTFail()
                }
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testGetPhoneMetadata_ServiceFailure() {
        let mockService = MockPhoneMetadataService()
        let underlyingError = NSError(domain: "com.test", code: 27, userInfo: nil)
        let expectedResult = ValidationResult.failure(.underlyingErrors(errors: [underlyingError], userInfo: [:], diagnosticsId: "1"))
        mockService.resultToReturn = expectedResult

        let expectation = self.expectation(description: "PhoneMetadata")

        mockService.getPhoneMetadata(mobileNumber: "1234567890") { result in
            if case let .failure(error) = result {
                switch error {
                case .underlyingErrors:
                    break
                default:
                    XCTFail("Expected underlyingErrors but got \(error)")
                }
                expectation.fulfill()
            } else {
                XCTFail("Expected failure but got success")
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
#endif
