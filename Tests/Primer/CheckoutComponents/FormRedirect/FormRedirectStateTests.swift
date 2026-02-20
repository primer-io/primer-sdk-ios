//
//  FormRedirectStateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class FormRedirectStateTests: XCTestCase {

    // MARK: - isSubmitEnabled Tests

    func test_isSubmitEnabled_emptyFields_returnsFalse() {
        let state = FormRedirectState()
        XCTAssertFalse(state.isSubmitEnabled)
    }

    func test_isSubmitEnabled_allFieldsValid_returnsTrue() {
        let state = FormRedirectTestData.validBlikState
        XCTAssertTrue(state.isSubmitEnabled)
    }

    func test_isSubmitEnabled_someFieldsInvalid_returnsFalse() {
        var state = FormRedirectState()
        state.fields = [FormRedirectTestData.invalidBlikField]
        XCTAssertFalse(state.isSubmitEnabled)
    }

    func test_isSubmitEnabled_multipleFieldsAllValid_returnsTrue() {
        var state = FormRedirectState()
        state.fields = [FormRedirectTestData.validBlikField, FormRedirectTestData.validMBWayField]
        XCTAssertTrue(state.isSubmitEnabled)
    }

    func test_isSubmitEnabled_multipleFieldsOneInvalid_returnsFalse() {
        var state = FormRedirectState()
        state.fields = [FormRedirectTestData.validBlikField, FormRedirectTestData.invalidMBWayField]
        XCTAssertFalse(state.isSubmitEnabled)
    }

    // MARK: - isTerminal Tests

    func test_isTerminal_allStatuses() {
        let expectations: [(FormRedirectState.Status, Bool)] = [
            (.ready, false),
            (.submitting, false),
            (.awaitingExternalCompletion, false),
            (.success, true),
            (.failure("error"), true)
        ]

        for (status, expected) in expectations {
            var state = FormRedirectState()
            state.status = status
            XCTAssertEqual(state.isTerminal, expected, "isTerminal for \(status) should be \(expected)")
        }
    }
}
