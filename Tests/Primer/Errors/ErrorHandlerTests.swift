//
//  ErrorHandlerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class ErrorHandlerTests: XCTestCase {

    private var sut: ErrorHandler!

    override func setUp() {
        super.setUp()
        sut = ErrorHandler()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - event(for:) — diagnosticsId is preserved for every PrimerErrorProtocol error

    func testEvent_forInternalError_preservesDiagnosticsId() {
        let error = InternalError.serverError(status: 500, diagnosticsId: "internal-diag-123")

        let properties = sut.event(for: error).properties as? MessageEventProperties

        XCTAssertEqual(properties?.diagnosticsId, "internal-diag-123")
    }

    func testEvent_forPrimerError_preservesDiagnosticsId() {
        let error = PrimerError.unknown(diagnosticsId: "primer-diag-456")

        let properties = sut.event(for: error).properties as? MessageEventProperties

        XCTAssertEqual(properties?.diagnosticsId, "primer-diag-456")
    }

    func testEvent_for3DSError_preservesDiagnosticsId() {
        let error = Primer3DSErrorContainer.missingSdkDependency()

        let properties = sut.event(for: error).properties as? MessageEventProperties

        XCTAssertEqual(properties?.diagnosticsId, error.diagnosticsId)
    }

    func testEvent_forGenericNSError_hasNilDiagnosticsId() {
        let error = NSError(domain: "TestDomain", code: 500, userInfo: ["test": "data"])

        let properties = sut.event(for: error).properties as? MessageEventProperties

        XCTAssertNil(properties?.diagnosticsId)
    }

    // MARK: - handle(error:)

    func testHandle_withFilteredErrors_doesNotThrow() {
        let errors: [PrimerError] = [
            .applePayNoCardsInWallet(diagnosticsId: "test-1"),
            .applePayDeviceNotSupported(diagnosticsId: "test-2")
        ]

        for error in errors {
            XCTAssertNoThrow(sut.handle(error: error))
        }
    }

    func testHandle_withVariousErrors_doesNotThrow() {
        let errors: [Error] = [
            PrimerError.unableToPresentApplePay(diagnosticsId: "test-1"),
            PrimerError.unknown(diagnosticsId: "test-2"),
            InternalError.noData(),
            NSError(domain: "TestDomain", code: 1)
        ]

        for error in errors {
            XCTAssertNoThrow(sut.handle(error: error))
        }
    }
}
