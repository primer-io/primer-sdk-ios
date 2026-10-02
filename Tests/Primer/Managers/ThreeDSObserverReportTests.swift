//
//  ThreeDSObserverReportTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class ThreeDSObserverReportTests: XCTestCase {

    private var observer: RecordingRequiredActionObserver!
    private var sut: ThreeDSObserverReport!

    override func setUp() {
        super.setUp()
        observer = RecordingRequiredActionObserver()
        sut = ThreeDSObserverReport(observer: observer)
    }

    override func tearDown() {
        sut = nil
        observer = nil
        super.tearDown()
    }

    func test_challengeShown_reportsTheProtocolVersionOfTheBeginAuthChallenge() async throws {
        sut.beginAuthResponded(with: try beginAuthentication([
            "responseCode": "CHALLENGE",
            "protocolVersion": "2.2.0",
            "transactionId": "tx_1",
            "acsTransactionId": "acs_tx_1",
            "acsReferenceNumber": "acs_ref",
            "acsSignedContent": "signed",
            "dsTransactionId": "ds_tx_1",
            "acsRenderingType": "01",
            "acsChallengeMandated": "Y",
            "statusUrl": "https://example.com/status"
        ]))

        await sut.challengeShown(provider: "NETCETERA")

        XCTAssertEqual(observer.calls, [.threeDSChallengeShown(provider: "NETCETERA", protocolVersion: "2.2.0")])
    }

    func test_challengeShown_withoutABeginAuthChallenge_reportsNoProtocolVersion() async {
        await sut.challengeShown(provider: "NETCETERA")

        XCTAssertEqual(observer.calls, [.threeDSChallengeShown(provider: "NETCETERA", protocolVersion: nil)])
    }

    func test_noChallengeNeeded_reportsTheBeginAuthOutcomeWithItsSkippedReason() async throws {
        sut.beginAuthResponded(with: try beginAuthentication([
            "responseCode": "SKIPPED",
            "skippedReasonCode": "ACQUIRER_NOT_CONFIGURED",
            "skippedReasonText": "Acquirer not configured"
        ]))

        await sut.noChallengeNeeded()

        XCTAssertEqual(observer.calls, [.threeDSCompleted(authenticationOutcome: "SKIPPED", skippedReasonCode: "ACQUIRER_NOT_CONFIGURED")])
    }

    func test_noChallengeNeeded_keepsASkippedReasonThisSDKDoesNotKnow() async throws {
        sut.beginAuthResponded(with: try beginAuthentication([
            "responseCode": "SKIPPED",
            "skippedReasonCode": "A_REASON_THIS_SDK_DOES_NOT_KNOW",
            "skippedReasonText": "Unknown reason"
        ]))

        await sut.noChallengeNeeded()

        XCTAssertEqual(observer.calls, [.threeDSCompleted(authenticationOutcome: "SKIPPED", skippedReasonCode: "A_REASON_THIS_SDK_DOES_NOT_KNOW")])
    }

    func test_noChallengeNeeded_reportsAFrictionlessSuccess() async throws {
        sut.beginAuthResponded(with: try beginAuthentication(["responseCode": "AUTH_SUCCESS"]))

        await sut.noChallengeNeeded()

        XCTAssertEqual(observer.calls, [.threeDSCompleted(authenticationOutcome: "AUTH_SUCCESS", skippedReasonCode: nil)])
    }

    func test_noChallengeNeeded_withAResponseThatIsNoOutcome_reportsNothing() async throws {
        sut.beginAuthResponded(with: try beginAuthentication(["responseCode": "NOT_PERFORMED"]))

        await sut.noChallengeNeeded()

        XCTAssertEqual(observer.calls, [])
    }

    func test_noChallengeNeeded_beforeABeginAuthResponse_reportsNothing() async {
        await sut.noChallengeNeeded()

        XCTAssertEqual(observer.calls, [])
    }

    func test_continued_reportsTheContinueAuthOutcome() async throws {
        let authentication = try JSONDecoder().decode(ThreeDS.Authentication.self, from: Data(#"{"responseCode":"AUTH_FAILED"}"#.utf8))

        await sut.continued(with: authentication)

        XCTAssertEqual(observer.calls, [.threeDSCompleted(authenticationOutcome: "AUTH_FAILED", skippedReasonCode: nil)])
    }

    func test_continued_withoutAnAuthentication_reportsNothing() async {
        await sut.continued(with: nil)

        XCTAssertEqual(observer.calls, [])
    }

    private func beginAuthentication(_ authentication: [String: Any]) throws -> ThreeDSAuthenticationProtocol {
        let json: [String: Any] = [
            "authentication": authentication,
            "resumeToken": "resume_token",
            "token": try JSONSerialization.jsonObject(with: JSONEncoder().encode(Mocks.primerPaymentMethodTokenData))
        ]
        return try JSONDecoder().decode(ThreeDS.BeginAuthResponse.self, from: JSONSerialization.data(withJSONObject: json)).authentication
    }
}
