//
//  KlarnaWidgetStatusTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
@_spi(PrimerInternal) import PrimerFoundation
@testable @_spi(PrimerInternal) import PrimerSDK
import XCTest

final class KlarnaWidgetStatusTests: XCTestCase {
    func testReadyNamesTheFormForTheAuthorizeStep() {
        let status = KlarnaWidgetStatus.ready(instanceId: "klarnaWidget")
        XCTAssertEqual(status.type, "ready")
        XCTAssertEqual(status.data, ["show_form": .bool(true), "instanceId": .string("klarnaWidget")])
    }

    func testUnavailableSaysThereIsNoFormAndWhy() {
        let status = KlarnaWidgetStatus.unavailable(KlarnaWidgetError(code: "NO_CATEGORY", message: "none"))
        XCTAssertEqual(status.type, "unavailable")
        XCTAssertEqual(status.data, ["show_form": .bool(false), "code": .string("NO_CATEGORY"), "message": .string("none")])
    }

    func testUnavailableWithoutAnErrorOnlySaysThereIsNoForm() {
        XCTAssertEqual(KlarnaWidgetStatus.unavailable().data, ["show_form": .bool(false)])
    }

    func testFailedCarriesKlarnasError() {
        let status = KlarnaWidgetStatus.failed(KlarnaWidgetError(code: "klarna-sdk-error", message: "boom"))
        XCTAssertEqual(status.type, "failed")
        XCTAssertEqual(status.data, ["code": .string("klarna-sdk-error"), "message": .string("boom")])
    }

    func testTheNodeIdNamesTheFormAndTheCategoryStandsInForExpandedNodes() {
        let named = KlarnaWidgetComponent.Params(id: "klarnaWidget", props: .object(["category": .string("pay_later")]))
        let expanded = KlarnaWidgetComponent.Params(id: nil, props: .object(["category": .string("pay_later")]))
        XCTAssertEqual(named.formKey, "klarnaWidget")
        XCTAssertEqual(expanded.formKey, "klarna.widget:pay_later")
    }

    func testANodeWithoutACategoryIsUnavailableAndWithoutATokenFails() {
        let noCategory = KlarnaWidgetComponent.Params(id: "w", props: .object(["clientToken": .string("t"), "category": .string("")]))
        let noToken = KlarnaWidgetComponent.Params(id: "w", props: .object(["category": .string("pay_later")]))
        XCTAssertEqual(noCategory.unloadable, .unavailable(KlarnaWidgetError(code: "NO_CATEGORY", message: "No payment category to load")))
        guard case let .failed(error) = noToken.unloadable else { return XCTFail("expected failed") }
        XCTAssertEqual(error.code, "MOUNT")
    }
}
#endif
