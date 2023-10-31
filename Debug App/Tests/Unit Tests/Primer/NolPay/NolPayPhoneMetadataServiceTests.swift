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
                XCTAssert(validationStatus == .valid)
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
                XCTAssertEqual(validationStatus, .invalid(errors: [validationError]))
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
                XCTAssertEqual(error.errorCode, 27)
                expectation.fulfill()
            } else {
                XCTFail("Expected failure but got success")
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
#endif
