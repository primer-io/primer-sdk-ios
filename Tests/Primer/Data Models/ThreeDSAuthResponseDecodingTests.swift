//
//  ThreeDSAuthResponseDecodingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerSDK
import XCTest

/// The 3DS service reads the protocol version and the skipped reason for analytics from these decoded types.
final class ThreeDSAuthResponseDecodingTests: XCTestCase {

    func test_beginAuth_appChallenge_decodesAsAppV2WithItsProtocolVersion() throws {
        let response: ThreeDS.BeginAuthResponse = try decode(authentication: [
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
        ])

        let challenge = try XCTUnwrap(response.authentication as? ThreeDS.AppV2ChallengeAPIResponse)
        XCTAssertEqual(challenge.protocolVersion, "2.2.0")
    }

    func test_beginAuth_skipped_decodesWithItsSkippedReason() throws {
        let response: ThreeDS.BeginAuthResponse = try decode(authentication: [
            "responseCode": "SKIPPED",
            "skippedReasonCode": "ACQUIRER_NOT_CONFIGURED",
            "skippedReasonText": "Acquirer not configured"
        ])

        let skipped = try XCTUnwrap(response.authentication as? ThreeDS.SkippedAPIResponse)
        XCTAssertEqual(skipped.skippedReasonCode.rawValue, "ACQUIRER_NOT_CONFIGURED")
    }

    func test_continueAuth_skippedWithAnUnknownReason_stillDecodes() throws {
        let response: ThreeDS.PostAuthResponse = try decode(authentication: [
            "responseCode": "SKIPPED",
            "skippedReasonCode": "A_REASON_THIS_SDK_DOES_NOT_KNOW"
        ])

        XCTAssertEqual(response.authentication?.responseCode, .skipped)
        XCTAssertEqual(response.authentication?.skippedReasonCode, "A_REASON_THIS_SDK_DOES_NOT_KNOW")
    }

    private func decode<Response: Decodable>(authentication: [String: Any]) throws -> Response {
        let token = PrimerPaymentMethodTokenData(
            analyticsId: "analytics_id",
            id: "token_id",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .paymentCard,
            paymentMethodType: "PAYMENT_CARD",
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: "token",
            tokenType: .singleUse,
            vaultData: nil
        )
        let json: [String: Any] = [
            "authentication": authentication,
            "resumeToken": "resume_token",
            "token": try JSONSerialization.jsonObject(with: JSONEncoder().encode(token))
        ]
        return try JSONDecoder().decode(Response.self, from: JSONSerialization.data(withJSONObject: json))
    }
}
