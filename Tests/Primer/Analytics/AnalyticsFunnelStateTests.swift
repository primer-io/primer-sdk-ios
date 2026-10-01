//
//  AnalyticsFunnelStateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

/// The contract's per-session rules, one scenario per test.
final class AnalyticsFunnelStateTests: XCTestCase {

    private let card = "PAYMENT_CARD"
    private let payPal = "PAYPAL"
    private var sut: AnalyticsFunnelState!

    override func setUp() {
        super.setUp()
        let ids = AttemptIds()
        sut = AnalyticsFunnelState(makeAttemptId: { ids.next() })
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Attempts and selection

    func test_selection_startsAnAttempt() {
        let outputs = sut.process(.paymentMethodSelection, metadata: payment(card))

        XCTAssertEqual(names(outputs), [.paymentMethodSelection])
        XCTAssertEqual(outputs.first?.envelope.attemptId, "attempt-1")
        XCTAssertEqual(outputs.first?.envelope.paymentMethod, card)
    }

    func test_selection_sameMethodAgain_isNotSentTwice() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))

        XCTAssertTrue(sut.process(.paymentMethodSelection, metadata: payment(card)).isEmpty)
    }

    func test_selection_afterLeavingTheMethod_startsANewAttemptWithoutASecondSelection() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentMethodUnselected, metadata: nil)

        XCTAssertTrue(sut.process(.paymentMethodSelection, metadata: payment(card)).isEmpty)
        let submitted = sut.process(.paymentSubmitted, metadata: payment(card))
        XCTAssertEqual(submitted.first?.envelope.attemptId, "attempt-2")
    }

    func test_selection_ofAnotherMethod_unselectsTheOpenOne() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))

        let outputs = sut.process(.paymentMethodSelection, metadata: payment(payPal))

        XCTAssertEqual(names(outputs), [.paymentMethodUnselected, .paymentMethodSelection])
        XCTAssertEqual(outputs[0].metadata?.paymentMethod, card)
        XCTAssertEqual(outputs[0].metadata?.paymentEvent?.reason, "shopper_cancel")
        XCTAssertEqual(outputs[0].envelope.attemptId, "attempt-1")
        XCTAssertEqual(outputs[1].envelope.attemptId, "attempt-2")
    }

    // MARK: - Reattempts

    func test_selection_afterAFailure_sendsReattemptedFirst() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentFailure, metadata: payment(card))

        let outputs = sut.process(.paymentMethodSelection, metadata: payment(payPal))

        XCTAssertEqual(names(outputs), [.paymentReattempted, .paymentMethodSelection])
        XCTAssertEqual(outputs[0].metadata?.paymentMethod, payPal)
        XCTAssertEqual(outputs[0].metadata?.paymentEvent?.previousPaymentMethod, card)
        XCTAssertEqual(outputs[0].envelope.attemptId, "attempt-2")
    }

    // A saved method is paid from the list, so no selection comes first.
    func test_submitted_afterAFailure_sendsReattemptedFirst() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentFailure, metadata: payment(card))

        XCTAssertEqual(names(sut.process(.paymentSubmitted, metadata: payment(card))), [.paymentReattempted, .paymentSubmitted])
    }

    func test_retry_startsANewAttempt_withThePreviousMethod() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentFailure, metadata: payment(card))

        let retry = sut.process(.paymentReattempted, metadata: nil)
        let submitted = sut.process(.paymentSubmitted, metadata: payment(card))

        XCTAssertEqual(names(retry), [.paymentReattempted])
        XCTAssertEqual(retry.first?.metadata?.paymentEvent?.previousPaymentMethod, card)
        XCTAssertEqual(retry.first?.envelope.attemptId, "attempt-2")
        XCTAssertEqual(names(submitted), [.paymentSubmitted])
    }

    // Retry and the retried submit run in separate tasks, so the submit can arrive first.
    func test_retry_afterTheRetriedAttemptAlreadyStarted_isNotSentTwice() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentFailure, metadata: payment(card))
        let submitted = sut.process(.paymentSubmitted, metadata: payment(card))

        XCTAssertEqual(names(submitted), [.paymentReattempted, .paymentSubmitted])
        XCTAssertTrue(sut.process(.paymentReattempted, metadata: nil).isEmpty)
        XCTAssertEqual(sut.process(.paymentProcessingStarted, metadata: payment(card)).first?.envelope.attemptId, "attempt-2")
    }

    func test_retry_afterAMerchantAbort_startsANewAttemptWithoutReattempted() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentMethodUnselected, metadata: .payment(PaymentEvent(paymentMethod: card, reason: "merchant_abort")))

        XCTAssertTrue(sut.process(.paymentReattempted, metadata: nil).isEmpty)
        XCTAssertEqual(sut.process(.paymentProcessingStarted, metadata: payment(card)).first?.envelope.attemptId, "attempt-2")
    }

    // A merchant's own pay button submits again without the SDK's retry.
    func test_selectionOnResubmit_afterAFailure_reopensTheAttemptForAMerchantAbort() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentFailure, metadata: payment(card))

        let resubmit = sut.process(.paymentMethodSelection, metadata: payment(card))
        let abort = sut.process(.paymentMethodUnselected, metadata: .payment(PaymentEvent(paymentMethod: card, reason: "merchant_abort")))

        XCTAssertEqual(names(resubmit), [.paymentReattempted])
        XCTAssertEqual(names(abort), [.paymentMethodUnselected])
        XCTAssertEqual(abort.first?.envelope.attemptId, "attempt-2")
    }

    func test_detailsEntered_afterSubmitted_isDropped() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentSubmitted, metadata: payment(card))

        XCTAssertTrue(sut.process(.paymentDetailsEntered, metadata: payment(card)).isEmpty)
    }

    // MARK: - One outcome per attempt

    func test_failure_afterAMerchantAbort_isDropped() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        let abort = sut.process(
            .paymentMethodUnselected,
            metadata: .payment(PaymentEvent(paymentMethod: card, reason: "merchant_abort"))
        )

        XCTAssertEqual(names(abort), [.paymentMethodUnselected])
        XCTAssertTrue(sut.process(.paymentFailure, metadata: payment(card)).isEmpty)
    }

    func test_secondOutcome_forTheSameAttempt_isDropped() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentSuccess, metadata: payment(card))

        XCTAssertTrue(sut.process(.paymentFailure, metadata: payment(card)).isEmpty)
    }

    func test_outcome_withNoAttemptYet_isSent() {
        let outputs = sut.process(.paymentSuccess, metadata: payment("APPLE_PAY"))

        XCTAssertEqual(names(outputs), [.paymentSuccess])
        XCTAssertEqual(outputs.first?.envelope.attemptId, "attempt-1")
    }

    // A checkout that failed to load, which is not a payment.
    func test_failure_withNoAttemptAndNoMethod_isDropped() {
        XCTAssertTrue(sut.process(.paymentFailure, metadata: payment("")).isEmpty)
        XCTAssertTrue(sut.process(.paymentSuccess, metadata: .general()).isEmpty)
    }

    func test_unselected_withNoOpenAttempt_isDropped() {
        XCTAssertTrue(sut.process(.paymentMethodUnselected, metadata: nil).isEmpty)
    }

    func test_unselected_forAMethodTheShopperAlreadyLeft_isDropped() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(payPal))

        XCTAssertTrue(sut.process(.paymentMethodUnselected, metadata: payment(card)).isEmpty)
    }

    // MARK: - Session events

    func test_flowExited_carriesTheLastStep_andIsSentOnce() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentSubmitted, metadata: payment(card))

        let exit = sut.process(.paymentFlowExited, metadata: nil)

        XCTAssertEqual(exit.first?.envelope.lastStep, "PAYMENT_SUBMITTED")
        XCTAssertEqual(exit.first?.envelope.paymentMethod, card)
        XCTAssertTrue(sut.process(.paymentFlowExited, metadata: nil).isEmpty)
    }

    func test_flowExited_afterASuccess_isDropped() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentSuccess, metadata: payment(card))

        XCTAssertTrue(sut.process(.paymentFlowExited, metadata: nil).isEmpty)
    }

    func test_checkoutFlowStarted_isSentOnce() {
        XCTAssertEqual(names(sut.process(.checkoutFlowStarted, metadata: .general())), [.checkoutFlowStarted])
        XCTAssertTrue(sut.process(.checkoutFlowStarted, metadata: .general()).isEmpty)
    }

    func test_eventsBeforeAnyAttempt_haveNoAttemptId() {
        XCTAssertNil(sut.process(.sdkInitStart, metadata: nil).first?.envelope.attemptId)
    }

    // MARK: - Envelope

    func test_paymentId_isKeptForTheAttempt_andClearedByTheNextOne() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(payPal))
        _ = sut.process(.paymentReturnedFromThirdParty, metadata: .payment(PaymentEvent(paymentMethod: payPal, paymentId: "pay_1")))

        XCTAssertEqual(sut.process(.paymentSubmitted, metadata: payment(payPal)).first?.envelope.paymentId, "pay_1")

        _ = sut.process(.paymentFailure, metadata: payment(payPal))
        let next = sut.process(.paymentMethodSelection, metadata: payment(card))
        XCTAssertNil(next.last?.envelope.paymentId)
    }

    func test_emptyPaymentMethod_takesTheAttemptsMethod() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))

        let threeDS = sut.process(.paymentThreeds, metadata: .threeDS(ThreeDSEvent(paymentMethod: "", provider: "NETCETERA")))

        XCTAssertNil(threeDS.first?.metadata?.paymentMethod)
        XCTAssertEqual(threeDS.first?.envelope.paymentMethod, card)
        XCTAssertEqual(threeDS.first?.envelope.attemptId, "attempt-1")
    }

    func test_cardRedirect_afterSubmitted_staysInTheAttemptWithItsPaymentId() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentSubmitted, metadata: payment(card))

        let redirect = sut.process(
            .paymentRedirectToThirdParty,
            metadata: .redirect(RedirectEvent(paymentMethod: "", destinationUrl: "https://bank.example.com", paymentId: "pay_1"))
        )
        let returned = sut.process(.paymentReturnedFromThirdParty, metadata: .payment(PaymentEvent(paymentMethod: "")))

        XCTAssertEqual(names(redirect + returned), [.paymentRedirectToThirdParty, .paymentReturnedFromThirdParty])
        XCTAssertEqual(returned.first?.envelope.paymentMethod, card)
        XCTAssertEqual(returned.first?.envelope.attemptId, "attempt-1")
        XCTAssertEqual(returned.first?.envelope.paymentId, "pay_1")
    }

    // MARK: - 3DS outcome

    func test_threeDSOutcome_goesOnTheAttemptsOutcomeOnly() {
        let outcome = AnalyticsFunnelState.ThreeDSOutcome(authenticationOutcome: "AUTH_SUCCESS", skippedReasonCode: nil)
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        sut.recordThreeDSOutcome(outcome)

        let processing = sut.process(.paymentProcessingStarted, metadata: payment(card))
        let success = sut.process(.paymentSuccess, metadata: payment(card))

        XCTAssertNil(processing.first?.envelope.threeDSOutcome)
        XCTAssertEqual(success.first?.envelope.threeDSOutcome, outcome)
    }

    func test_threeDSOutcome_doesNotCarryIntoTheNextAttempt() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        sut.recordThreeDSOutcome(AnalyticsFunnelState.ThreeDSOutcome(authenticationOutcome: "AUTH_FAILED", skippedReasonCode: nil))

        let switched = sut.process(.paymentMethodSelection, metadata: payment(payPal))
        let success = sut.process(.paymentSuccess, metadata: payment(payPal))

        XCTAssertEqual(names(switched), [.paymentMethodUnselected, .paymentMethodSelection])
        XCTAssertNil(success.first?.envelope.threeDSOutcome)
    }

    func test_threeDSOutcome_afterTheAttemptEnded_doesNotReachTheRetry() {
        _ = sut.process(.paymentMethodSelection, metadata: payment(card))
        _ = sut.process(.paymentFailure, metadata: payment(card))
        sut.recordThreeDSOutcome(AnalyticsFunnelState.ThreeDSOutcome(authenticationOutcome: "SKIPPED", skippedReasonCode: "GATEWAY_UNAVAILABLE"))

        _ = sut.process(.paymentReattempted, metadata: nil)
        let failure = sut.process(.paymentFailure, metadata: payment(card))

        XCTAssertNil(failure.first?.envelope.threeDSOutcome)
    }

    // MARK: - Helpers

    private func payment(_ method: String) -> AnalyticsEventMetadata {
        .payment(PaymentEvent(paymentMethod: method))
    }

    private func names(_ outputs: [AnalyticsFunnelState.Output]) -> [AnalyticsEventType] {
        outputs.map(\.eventType)
    }
}

private final class AttemptIds: @unchecked Sendable {
    private var count = 0
    private let lock = NSLock()

    func next() -> String {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return "attempt-\(count)"
    }
}
