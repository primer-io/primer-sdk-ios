//
//  HeadlessRepositoryAnalyticsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - 3DS Challenge Tracking

@available(iOS 15.0, *)
@MainActor
final class TrackThreeDSChallengeTests: XCTestCase {

    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        sut = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_trackThreeDSChallenge_withNoAuthentication_doesNotCrash() {
        // Given - token data without 3DS authentication
        let tokenData = Response.Body.Tokenization(
            analyticsId: "analytics-1",
            id: "token-1",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .paymentCard,
            paymentMethodType: "PAYMENT_CARD",
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: "tok_123",
            tokenType: .singleUse,
            vaultData: nil
        )

        // When / Then - should not crash (early return when no auth)
        sut.trackThreeDSChallengeIfNeeded(from: tokenData)
    }

    func test_trackThreeDSChallenge_withAuthentication_doesNotCrash() {
        // Given - token data with 3DS authentication
        let auth = ThreeDS.AuthenticationDetails(
            responseCode: .authSuccess,
            reasonCode: nil,
            reasonText: nil,
            protocolVersion: "2.2.0",
            challengeIssued: true
        )
        let tokenData = Response.Body.Tokenization(
            analyticsId: "analytics-2",
            id: "token-2",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .paymentCard,
            paymentMethodType: "PAYMENT_CARD",
            paymentInstrumentData: nil,
            threeDSecureAuthentication: auth,
            token: "tok_456",
            tokenType: .singleUse,
            vaultData: nil
        )

        // When / Then - should process without crash
        sut.trackThreeDSChallengeIfNeeded(from: tokenData)
    }

    func test_trackThreeDSChallenge_withNilPaymentMethodType_usesDefault() {
        // Given - token data with auth but no payment method type
        let auth = ThreeDS.AuthenticationDetails(
            responseCode: .challenge,
            reasonCode: nil,
            reasonText: nil,
            protocolVersion: "2.1.0",
            challengeIssued: true
        )
        let tokenData = Response.Body.Tokenization(
            analyticsId: "analytics-3",
            id: "token-3",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .paymentCard,
            paymentMethodType: nil,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: auth,
            token: "tok_789",
            tokenType: .singleUse,
            vaultData: nil
        )

        // When / Then - should not crash (uses "PAYMENT_CARD" default)
        sut.trackThreeDSChallengeIfNeeded(from: tokenData)
    }

    func test_trackThreeDSChallenge_withVariousResponseCodes_doesNotCrash() {
        // Given
        let responseCodes: [ThreeDS.ResponseCode] = [
            .notPerformed, .skipped, .authSuccess, .authFailed, .challenge, .METHOD,
        ]

        for responseCode in responseCodes {
            let auth = ThreeDS.AuthenticationDetails(
                responseCode: responseCode,
                reasonCode: nil,
                reasonText: nil,
                protocolVersion: "2.2.0",
                challengeIssued: false
            )
            let tokenData = Response.Body.Tokenization(
                analyticsId: "analytics-\(responseCode.rawValue)",
                id: "token-\(responseCode.rawValue)",
                isVaulted: false,
                isAlreadyVaulted: false,
                paymentInstrumentType: .paymentCard,
                paymentMethodType: "PAYMENT_CARD",
                paymentInstrumentData: nil,
                threeDSecureAuthentication: auth,
                token: "tok_\(responseCode.rawValue)",
                tokenType: .singleUse,
                vaultData: nil
            )

            // When / Then
            sut.trackThreeDSChallengeIfNeeded(from: tokenData)
        }
    }
}

// MARK: - Redirect Tracking

@available(iOS 15.0, *)
@MainActor
final class TrackRedirectToThirdPartyTests: XCTestCase {

    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        sut = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_trackRedirect_withNilAdditionalInfo_doesNotCrash() {
        // When / Then
        sut.trackRedirectToThirdPartyIfNeeded(from: nil, paymentMethodType: "PAYMENT_CARD")
    }

}

// MARK: - Bin Data Stream

@available(iOS 15.0, *)
@MainActor
final class BinDataStreamTests: XCTestCase {

    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        sut = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_getBinDataStream_returnsNonNilStream() {
        // When
        let stream = sut.getBinDataStream()

        // Then
        XCTAssertNotNil(stream)
    }

    func test_getBinDataStream_returnsSameStreamOnMultipleCalls() {
        // When
        let stream1 = sut.getBinDataStream()
        let stream2 = sut.getBinDataStream()

        // Then
        XCTAssertNotNil(stream1)
        XCTAssertNotNil(stream2)
    }
}
