//
//  ClientSessionCardNetworkSyncTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ClientSessionCardNetworkSyncTests: XCTestCase {

    private var actions: MockClientSessionActionsModule!
    private var sut: ClientSessionCardNetworkSync!
    private var isSurchargeSession = true
    private var session: ClientSession.APIResponse?
    private var previousIntent: PrimerSessionIntent?
    private var previousIntegrationType: PrimerSDKIntegrationType?

    override func setUp() {
        super.setUp()
        previousIntent = PrimerInternal.shared.intent
        previousIntegrationType = PrimerInternal.shared.sdkIntegrationType
        PrimerInternal.shared.intent = .checkout
        PrimerInternal.shared.sdkIntegrationType = .headless

        let actions = MockClientSessionActionsModule()
        self.actions = actions
        isSurchargeSession = true
        session = Self.makeSession()
        sut = ClientSessionCardNetworkSync(
            actionsFactory: { actions },
            isSurchargeSession: { [unowned self] in isSurchargeSession },
            currentSession: { [unowned self] in session }
        )
    }

    override func tearDown() {
        PrimerInternal.shared.intent = previousIntent
        PrimerInternal.shared.sdkIntegrationType = previousIntegrationType
        sut = nil
        actions = nil
        session = nil
        super.tearDown()
    }

    func test_sync_withNetwork_selectsItOnTheSession() async {
        await sut.sync(.cartesBancaires)

        XCTAssertEqual(actions.selectPaymentMethodCalls.map(\.type), ["PAYMENT_CARD"])
        XCTAssertEqual(actions.selectPaymentMethodCalls.map(\.network), ["CARTES_BANCAIRES"])
    }

    func test_sync_sameNetworkTwice_sendsOnce() async {
        await sut.sync(.cartesBancaires)
        await sut.sync(.cartesBancaires)

        XCTAssertEqual(actions.selectPaymentMethodCalls.count, 1)
    }

    func test_sync_toNetworkWithoutSurcharge_stillSends() async {
        await sut.sync(.visa)

        await sut.sync(.masterCard)

        XCTAssertEqual(actions.selectPaymentMethodCalls.map(\.network), ["VISA", "MASTERCARD"])
    }

    func test_sync_nilWithNothingSelected_sendsNothing() async {
        await sut.sync(nil)

        XCTAssertTrue(actions.selectPaymentMethodCalls.isEmpty)
        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 0)
    }

    func test_sync_nilAfterNetwork_unselects() async {
        await sut.sync(.cartesBancaires)

        await sut.sync(nil)

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 1)
    }

    func test_sync_afterAnotherUpdateReplacedTheSession_sendsTheSameNetworkAgain() async {
        await sut.sync(.cartesBancaires)

        session = Self.makeSession()
        await sut.sync(.cartesBancaires)

        XCTAssertEqual(actions.selectPaymentMethodCalls.map(\.network), ["CARTES_BANCAIRES", "CARTES_BANCAIRES"])
    }

    func test_sync_afterFailure_retriesTheSameNetwork() async {
        actions.selectPaymentMethodError = TestError.networkFailure
        await sut.sync(.cartesBancaires)
        actions.selectPaymentMethodError = nil

        await sut.sync(.cartesBancaires)

        XCTAssertEqual(actions.selectPaymentMethodCalls.map(\.network), ["CARTES_BANCAIRES", "CARTES_BANCAIRES"])
    }

    func test_sync_whileAnUpdateIsInFlight_waitsForItThenSends() async throws {
        actions.selectPaymentMethodDelay = 0.2
        let first = Task { [sut] in await sut?.sync(.visa) }
        try await withTimeout(2.0) { [self] in
            while actions.selectPaymentMethodCalls.isEmpty { await Task.yield() }
        }
        let needsSyncWhileInFlight = await sut.needsSync(.visa)

        await sut.sync(.cartesBancaires)
        await first.value

        XCTAssertTrue(needsSyncWhileInFlight)
        XCTAssertEqual(actions.selectPaymentMethodCalls.map(\.network), ["VISA", "CARTES_BANCAIRES"])
        let needsSync = await sut.needsSync(.cartesBancaires)
        XCTAssertFalse(needsSync)
    }

    func test_release_afterNetwork_unselects() async {
        await sut.sync(.cartesBancaires)

        await sut.release()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 1)
    }

    func test_release_withNothingSent_sendsNothing() async {
        await sut.release()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 0)
    }

    func test_release_afterUnselect_sendsNothingMore() async {
        await sut.sync(.cartesBancaires)
        await sut.sync(nil)

        await sut.release()
        await sut.release()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 1)
    }

    func test_release_afterAFailedRelease_unselectsAgain() async {
        await sut.sync(.cartesBancaires)
        actions.unselectPaymentMethodError = TestError.networkFailure
        await sut.release()
        actions.unselectPaymentMethodError = nil

        await sut.release()
        await sut.release()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 2)
    }

    func test_release_afterAFailedUnselect_unselects() async {
        await sut.sync(.cartesBancaires)
        actions.unselectPaymentMethodError = TestError.networkFailure
        await sut.sync(nil)
        actions.unselectPaymentMethodError = nil

        await sut.release()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 2)
    }

    func test_release_twiceWhileTheFirstIsInFlight_unselectsOnce() async {
        await sut.sync(.cartesBancaires)
        actions.unselectPaymentMethodDelay = 0.2

        let first = Task { [sut] in await sut?.release() }
        let second = Task { [sut] in await sut?.release() }
        await first.value
        await second.value

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 1)
    }

    func test_release_afterPaymentStarted_sendsNothing() async {
        await sut.sync(.cartesBancaires)
        await sut.startPayment()

        await sut.release()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 0)
    }

    func test_release_afterPaymentFailed_unselects() async {
        await sut.sync(.cartesBancaires)
        await sut.startPayment()
        await sut.endPayment()

        await sut.release()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 1)
    }

    func test_release_afterPayTimeUpdate_unselects() async {
        await sut.markSynced(.cartesBancaires)

        await sut.release()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 1)
    }

    func test_release_whileAnUpdateIsInFlight_unselectsAtOnce() async throws {
        actions.selectPaymentMethodDelay = 0.2
        let first = Task { [sut] in await sut?.sync(.cartesBancaires) }
        try await withTimeout(2.0) { [self] in
            while actions.selectPaymentMethodCalls.isEmpty { await Task.yield() }
        }

        await sut.release()
        let unselectsBeforeTheUpdateReturned = actions.unselectPaymentMethodCallCount
        await first.value

        XCTAssertEqual(unselectsBeforeTheUpdateReturned, 1)
        let needsSync = await sut.needsSync(.cartesBancaires)
        XCTAssertTrue(needsSync)
    }

    func test_sync_whileReleaseIsInFlight_sendsTheNetworkAfterIt() async throws {
        await sut.sync(.cartesBancaires)
        actions.unselectPaymentMethodDelay = 0.2
        let release = Task { [sut] in await sut?.release() }
        try await withTimeout(2.0) { [self] in
            while actions.unselectPaymentMethodCallCount == 0 { await Task.yield() }
        }

        let needsSync = await sut.needsSync(.cartesBancaires)
        await sut.sync(.cartesBancaires)
        await release.value

        XCTAssertTrue(needsSync)
        XCTAssertEqual(actions.selectPaymentMethodCalls.map(\.network), ["CARTES_BANCAIRES", "CARTES_BANCAIRES"])
        let needsSyncAfter = await sut.needsSync(.cartesBancaires)
        XCTAssertFalse(needsSyncAfter)
    }

    func test_reset_forgetsAnEarlierCheckout() async {
        await sut.sync(.cartesBancaires)
        await sut.startPayment()

        await sut.reset()
        await sut.release()
        let unselectsAfterReset = actions.unselectPaymentMethodCallCount
        await sut.sync(.visa)
        await sut.release()

        XCTAssertEqual(unselectsAfterReset, 0)
        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 1)
        XCTAssertEqual(actions.selectPaymentMethodCalls.map(\.network), ["CARTES_BANCAIRES", "VISA"])
    }

    func test_markSynced_skipsTheSameNetwork() async {
        await sut.markSynced(.cartesBancaires)

        await sut.sync(.cartesBancaires)

        XCTAssertTrue(actions.selectPaymentMethodCalls.isEmpty)
    }

    func test_needsSync_reflectsTheSessionNetwork() async {
        await sut.sync(.cartesBancaires)

        let needsSameNetwork = await sut.needsSync(.cartesBancaires)
        let needsOtherNetwork = await sut.needsSync(.visa)
        XCTAssertFalse(needsSameNetwork)
        XCTAssertTrue(needsOtherNetwork)
    }

    func test_isEnabled_onlyForHeadlessAndCheckoutComponentsCheckoutWithSurcharge() {
        XCTAssertTrue(sut.isEnabled)

        isSurchargeSession = false
        XCTAssertFalse(sut.isEnabled)

        isSurchargeSession = true
        PrimerInternal.shared.sdkIntegrationType = .dropIn
        XCTAssertFalse(sut.isEnabled, "Drop-in sends its own client session actions")

        PrimerInternal.shared.sdkIntegrationType = .checkoutComponents
        XCTAssertTrue(sut.isEnabled)

        PrimerInternal.shared.sdkIntegrationType = .headless
        PrimerInternal.shared.intent = .vault
        XCTAssertFalse(sut.isEnabled)
    }

    private static func makeSession() -> ClientSession.APIResponse {
        ClientSession.APIResponse(clientSessionId: nil, paymentMethod: nil, order: nil, customer: nil, testId: nil)
    }
}
