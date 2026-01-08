//
//  CheckoutRouteTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class CheckoutRouteTests: XCTestCase {

    // MARK: - Route ID Tests

    func test_splash_hasCorrectId() {
        let route = CheckoutRoute.splash
        XCTAssertEqual(route.id, TestData.RouteIds.splash)
    }

    func test_loading_hasCorrectId() {
        let route = CheckoutRoute.loading
        XCTAssertEqual(route.id, TestData.RouteIds.loading)
    }

    func test_paymentMethodSelection_hasCorrectId() {
        let route = CheckoutRoute.paymentMethodSelection
        XCTAssertEqual(route.id, TestData.RouteIds.paymentMethodSelection)
    }

    func test_processing_hasCorrectId() {
        let route = CheckoutRoute.processing
        XCTAssertEqual(route.id, TestData.RouteIds.processing)
    }

    func test_success_hasCorrectId() {
        let result = CheckoutPaymentResult(paymentId: TestData.PaymentIds.test, amount: TestData.FormattedAmounts.tenDollars)
        let route = CheckoutRoute.success(result)
        XCTAssertEqual(route.id, TestData.RouteIds.success)
    }

    func test_failure_hasCorrectId() {
        let error = PrimerError.invalidValue(key: TestData.ErrorKeys.test, value: nil, reason: nil, diagnosticsId: TestData.DiagnosticsIds.test)
        let route = CheckoutRoute.failure(error)
        XCTAssertEqual(route.id, TestData.RouteIds.failure)
    }

    func test_paymentMethod_directContext_hasCorrectId() {
        let route = CheckoutRoute.paymentMethod(TestData.PaymentMethodTypes.card, .direct)
        XCTAssertEqual(route.id, TestData.RouteIds.paymentMethodCardDirect)
    }

    func test_paymentMethod_selectionContext_hasCorrectId() {
        let route = CheckoutRoute.paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection)
        XCTAssertEqual(route.id, TestData.RouteIds.paymentMethodCardSelection)
    }

    // MARK: - Navigation Behavior Tests

    func test_splash_hasResetBehavior() {
        let route = CheckoutRoute.splash
        XCTAssertEqual(route.navigationBehavior, .reset)
    }

    func test_loading_hasReplaceBehavior() {
        let route = CheckoutRoute.loading
        XCTAssertEqual(route.navigationBehavior, .replace)
    }

    func test_paymentMethodSelection_hasResetBehavior() {
        let route = CheckoutRoute.paymentMethodSelection
        XCTAssertEqual(route.navigationBehavior, .reset)
    }

    func test_paymentMethod_hasPushBehavior() {
        let route = CheckoutRoute.paymentMethod(TestData.PaymentMethodTypes.card, .direct)
        XCTAssertEqual(route.navigationBehavior, .push)
    }

    func test_processing_hasReplaceBehavior() {
        let route = CheckoutRoute.processing
        XCTAssertEqual(route.navigationBehavior, .replace)
    }

    func test_success_hasReplaceBehavior() {
        let result = CheckoutPaymentResult(paymentId: TestData.PaymentIds.test, amount: TestData.FormattedAmounts.tenDollars)
        let route = CheckoutRoute.success(result)
        XCTAssertEqual(route.navigationBehavior, NavigationBehavior.replace)
    }

    func test_failure_hasReplaceBehavior() {
        let error = PrimerError.invalidValue(key: TestData.ErrorKeys.test, value: nil, reason: nil, diagnosticsId: TestData.DiagnosticsIds.test)
        let route = CheckoutRoute.failure(error)
        XCTAssertEqual(route.navigationBehavior, NavigationBehavior.replace)
    }

    // MARK: - Hashable Tests

    func test_sameRoutes_areEqual() {
        XCTAssertEqual(CheckoutRoute.splash, CheckoutRoute.splash)
        XCTAssertEqual(CheckoutRoute.loading, CheckoutRoute.loading)
        XCTAssertEqual(CheckoutRoute.processing, CheckoutRoute.processing)
    }

    func test_differentRoutes_areNotEqual() {
        XCTAssertNotEqual(CheckoutRoute.splash, CheckoutRoute.loading)
        XCTAssertNotEqual(CheckoutRoute.loading, CheckoutRoute.processing)
    }

    func test_paymentMethod_sameTypeAndContext_areEqual() {
        let route1 = CheckoutRoute.paymentMethod(TestData.PaymentMethodTypes.card, .direct)
        let route2 = CheckoutRoute.paymentMethod(TestData.PaymentMethodTypes.card, .direct)
        XCTAssertEqual(route1, route2)
    }

    func test_paymentMethod_differentContext_areNotEqual() {
        let route1 = CheckoutRoute.paymentMethod(TestData.PaymentMethodTypes.card, .direct)
        let route2 = CheckoutRoute.paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection)
        XCTAssertNotEqual(route1, route2)
    }

    func test_paymentMethod_differentType_areNotEqual() {
        let route1 = CheckoutRoute.paymentMethod(TestData.PaymentMethodTypes.card, .direct)
        let route2 = CheckoutRoute.paymentMethod(TestData.PaymentMethodTypes.applePay, .direct)
        XCTAssertNotEqual(route1, route2)
    }

    func test_routes_hashCorrectly() {
        var set = Set<CheckoutRoute>()
        set.insert(.splash)
        set.insert(.loading)
        set.insert(.splash) // Duplicate

        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(.splash))
        XCTAssertTrue(set.contains(.loading))
    }
}

// MARK: - PresentationContext Tests

@available(iOS 15.0, *)
final class PresentationContextTests: XCTestCase {

    func test_direct_shouldNotShowBackButton() {
        let context = PresentationContext.direct
        XCTAssertFalse(context.shouldShowBackButton)
    }

    func test_fromPaymentSelection_shouldShowBackButton() {
        let context = PresentationContext.fromPaymentSelection
        XCTAssertTrue(context.shouldShowBackButton)
    }
}
