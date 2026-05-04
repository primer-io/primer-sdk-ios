//
//  VaultedPaymentMethodManagerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class VaultedPaymentMethodManagerTests: XCTestCase {

    private var sut: VaultedPaymentMethodManager!

    override func setUp() {
        super.setUp()
        sut = VaultedPaymentMethodManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeVaultedPaymentMethod(id: String = "vault_1") -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        let data = try! JSONSerialization.data(withJSONObject: ["last4Digits": "4242"]) // swiftlint:disable:this force_try
        let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: data
        )
        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics_\(id)"
        )
    }

    // MARK: - Initial State

    func test_initial_methods_isEmpty() {
        XCTAssertTrue(sut.methods.isEmpty)
    }

    func test_initial_selectedMethod_isNil() {
        XCTAssertNil(sut.selectedMethod)
    }

    // MARK: - setMethods

    func test_setMethods_withMethods_updatesArray() {
        // Given
        let methods = [makeVaultedPaymentMethod(id: "v1"), makeVaultedPaymentMethod(id: "v2")]

        // When
        sut.setMethods(methods)

        // Then
        XCTAssertEqual(sut.methods.count, 2)
    }

    func test_setMethods_withMethods_selectsFirstAsDefault() {
        // Given
        let methods = [makeVaultedPaymentMethod(id: "first"), makeVaultedPaymentMethod(id: "second")]

        // When
        sut.setMethods(methods)

        // Then
        XCTAssertEqual(sut.selectedMethod?.id, "first")
    }

    func test_setMethods_emptyList_clearsSelection() {
        // Given
        sut.setMethods([makeVaultedPaymentMethod()])

        // When
        sut.setMethods([])

        // Then
        XCTAssertTrue(sut.methods.isEmpty)
        XCTAssertNil(sut.selectedMethod)
    }

    func test_setMethods_deletedSelection_fallsBackToFirst() {
        // Given
        let method1 = makeVaultedPaymentMethod(id: "v1")
        let method2 = makeVaultedPaymentMethod(id: "v2")
        sut.setMethods([method1, method2])
        sut.setSelectedMethod(method2)

        // When
        sut.setMethods([method1])

        // Then
        XCTAssertEqual(sut.selectedMethod?.id, "v1")
    }

    func test_setMethods_retainsSelection_whenStillPresent() {
        // Given
        let method1 = makeVaultedPaymentMethod(id: "v1")
        let method2 = makeVaultedPaymentMethod(id: "v2")
        sut.setMethods([method1, method2])
        sut.setSelectedMethod(method2)

        // When
        sut.setMethods([method1, method2])

        // Then
        XCTAssertEqual(sut.selectedMethod?.id, "v2")
    }

    // MARK: - setSelectedMethod

    func test_setSelectedMethod_setsSelection() {
        // Given
        let method = makeVaultedPaymentMethod()

        // When
        sut.setSelectedMethod(method)

        // Then
        XCTAssertEqual(sut.selectedMethod?.id, "vault_1")
    }

    func test_setSelectedMethod_nil_clearsSelection() {
        // Given
        sut.setSelectedMethod(makeVaultedPaymentMethod())

        // When
        sut.setSelectedMethod(nil)

        // Then
        XCTAssertNil(sut.selectedMethod)
    }

    // MARK: - onSelectionChanged Callback

    func test_setSelectedMethod_callsOnSelectionChanged() {
        // Given
        var callbackMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
        var callCount = 0
        sut.onSelectionChanged = { method in
            callbackMethod = method
            callCount += 1
        }
        let method = makeVaultedPaymentMethod()

        // When
        sut.setSelectedMethod(method)

        // Then
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(callbackMethod?.id, "vault_1")
    }

    func test_setSelectedMethod_nil_callsOnSelectionChangedWithNil() {
        // Given
        var callbackMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = makeVaultedPaymentMethod()
        var callCount = 0
        sut.onSelectionChanged = { method in
            callbackMethod = method
            callCount += 1
        }

        // When
        sut.setSelectedMethod(nil)

        // Then
        XCTAssertEqual(callCount, 1)
        XCTAssertNil(callbackMethod)
    }

    func test_setMethods_doesNotCallOnSelectionChanged() {
        // Given
        var callCount = 0
        sut.onSelectionChanged = { _ in
            callCount += 1
        }

        // When
        sut.setMethods([makeVaultedPaymentMethod(id: "v1"), makeVaultedPaymentMethod(id: "v2")])

        // Then
        XCTAssertEqual(callCount, 0)
    }
}
