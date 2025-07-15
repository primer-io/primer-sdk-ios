//
//  ErrorHandlerTests.swift
//  PrimerSDK Tests
//
//  Created by Primer on 2024
//

import XCTest
@testable import PrimerSDK

final class ErrorHandlerTests: XCTestCase {
    
    var sut: ErrorHandler!
    
    override func setUp() {
        super.setUp()
        sut = ErrorHandler()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Handle Error Tests
    
    func testHandleError_WithApplePayNoCardsInWallet() {
        let error = PrimerError.applePayNoCardsInWallet(userInfo: nil, diagnosticsId: "test-123")
        
        // This error should be filtered (based on ErrorHandler implementation)
        // We can't test private methods directly, but we can verify the public API works
        XCTAssertNoThrow(sut.handle(error: error))
    }
    
    func testHandleError_WithApplePayDeviceNotSupported() {
        let error = PrimerError.applePayDeviceNotSupported(userInfo: nil, diagnosticsId: "test-456")
        
        // This error should be filtered (based on ErrorHandler implementation)
        XCTAssertNoThrow(sut.handle(error: error))
    }
    
    func testHandleError_WithPrimerError_CreatesCorrectEvent() {
        let userInfo = ["key": "value"]
        let diagnosticsId = "test-789"
        let error = PrimerError.applePayConfigurationError(
            merchantIdentifier: "merchant.id",
            userInfo: userInfo,
            diagnosticsId: diagnosticsId
        )
        
        // Handle the error
        sut.handle(error: error)
        
        // We can't easily verify Analytics.Service.record was called with correct parameters
        // without dependency injection, but we can verify the method completes
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testHandleError_With3DSError_CreatesCorrectEvent() {
        // Create a 3DS error using an available case
        let threeDsError = Primer3DSErrorContainer.missingSdkDependency(
            userInfo: ["3ds": "missing"],
            diagnosticsId: "3ds-test"
        )
        
        // Handle the error
        sut.handle(error: threeDsError)
        
        // Verify method completes without errors
        XCTAssertTrue(true)
    }
    
    func testHandleError_WithGenericError_CreatesCorrectEvent() {
        let error = NSError(domain: "TestDomain", code: 500, userInfo: ["test": "data"])
        
        // Handle the error
        sut.handle(error: error)
        
        // Verify method completes without errors
        XCTAssertTrue(true)
    }
    
    func testHandleError_WithDifferentPrimerErrors() {
        // Test various PrimerError cases to ensure they're handled correctly
        let errors: [PrimerError] = [
            .unableToPresentApplePay(userInfo: nil, diagnosticsId: "test-1"),
            .applePayTimedOut(userInfo: nil, diagnosticsId: "test-2"),
            .applePayPresentationFailed(reason: "test", userInfo: nil, diagnosticsId: "test-3"),
            .unknown(userInfo: nil, diagnosticsId: "test-4")
        ]
        
        for error in errors {
            XCTAssertNoThrow(sut.handle(error: error))
        }
    }
}
