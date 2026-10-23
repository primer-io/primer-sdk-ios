//
//  RawDataManagerCardNetworkSyncTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class RawDataManagerCardNetworkSyncTests: XCTestCase {

    private var actions: MockClientSessionActionsModule!
    private var sync: ClientSessionCardNetworkSync!
    private var sut: RawDataManager!

    override func setUpWithError() throws {
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod])
        let actions = MockClientSessionActionsModule()
        self.actions = actions
        sync = ClientSessionCardNetworkSync(
            actionsFactory: { actions },
            isSurchargeSession: { true },
            currentSession: { nil }
        )
        sut = try RawDataManager(paymentMethodType: "PAYMENT_CARD")
        sut.cardNetworkSync = sync
    }

    override func tearDownWithError() throws {
        PrimerInternal.shared.intent = nil
        PrimerInternal.shared.sdkIntegrationType = nil
        sut = nil
        sync = nil
        actions = nil
        SDKSessionHelper.tearDown()
    }

    func test_releaseCardNetwork_takesTheSyncedNetworkOffTheSession() async {
        await sync.sync(.cartesBancaires)

        await sut.releaseCardNetwork()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 1)
    }

    func test_releaseCardNetwork_afterThePaymentStarted_keepsTheNetwork() async {
        await sync.sync(.cartesBancaires)
        await sync.startPayment()

        await sut.releaseCardNetwork()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 0)
    }

    func test_releaseCardNetwork_withNothingSynced_sendsNothing() async {
        await sut.releaseCardNetwork()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 0)
    }

    func test_releaseCardNetwork_afterAFailedPayment_takesTheNetworkOff() async {
        await startCardPayment()

        await sut.endCardPaymentIfFailed(checkoutData(status: "FAILED"))
        await sut.releaseCardNetwork()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 1)
    }

    func test_releaseCardNetwork_afterASuccessfulPayment_keepsTheNetwork() async {
        await startCardPayment()

        await sut.endCardPaymentIfFailed(checkoutData(status: "SUCCESS"))
        await sut.releaseCardNetwork()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 0)
    }

    func test_releaseCardNetwork_afterAPaymentWithoutAResult_keepsTheNetwork() async {
        await startCardPayment()

        await sut.endCardPaymentIfFailed(nil)
        await sut.releaseCardNetwork()

        XCTAssertEqual(actions.unselectPaymentMethodCallCount, 0)
    }

    private func startCardPayment() async {
        PrimerInternal.shared.intent = .checkout
        PrimerInternal.shared.sdkIntegrationType = .headless
        sut.rawData = PrimerCardData(
            cardNumber: "4035 5010 0000 0008",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: nil
        )
        await sync.sync(.cartesBancaires)
        await sync.startPayment()
    }

    private func checkoutData(status: String) -> PrimerCheckoutData {
        PrimerCheckoutData(
            payment: PrimerCheckoutDataPayment(id: "id", orderId: "order", paymentFailureReason: nil, status: status)
        )
    }
}
