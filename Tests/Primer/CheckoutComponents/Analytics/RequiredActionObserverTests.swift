//
//  RequiredActionObserverTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

/// What checkout analytics sends for the pages the shared core opens.
@available(iOS 15.0, *)
final class RequiredActionObserverTests: XCTestCase {

    private var sut: MockTrackingAnalyticsInteractor!

    override func setUp() {
        super.setUp()
        sut = MockTrackingAnalyticsInteractor()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_redirectOpened_tracksTheRedirectForTheOpenAttempt() async throws {
        // When
        await sut.redirectOpened(try XCTUnwrap(URL(string: "https://bank.example.com/pay?token=secret")), paymentId: "pay_1")

        // Then
        let events = await sut.trackedEvents
        XCTAssertEqual(events.map(\.eventType), [.paymentRedirectToThirdParty])
        XCTAssertNil(events.first?.metadata?.paymentMethod)
        XCTAssertEqual(events.first?.metadata?.redirectDestinationUrl, "https://bank.example.com")
        XCTAssertEqual(events.first?.metadata?.paymentId, "pay_1")
    }

    func test_redirectReturned_tracksTheReturnWithoutSubmitted() async {
        // When
        await sut.redirectReturned(paymentId: "pay_1")

        // Then
        let events = await sut.trackedEvents
        XCTAssertEqual(events.map(\.eventType), [.paymentReturnedFromThirdParty])
        XCTAssertNil(events.first?.metadata?.paymentMethod)
        XCTAssertEqual(events.first?.metadata?.paymentId, "pay_1")
    }

    func test_threeDSChallengeShown_tracksPaymentThreedsForTheOpenAttempt() async {
        // When
        await sut.threeDSChallengeShown(provider: "PROCESSOR", protocolVersion: nil)

        // Then
        let events = await sut.trackedEvents
        XCTAssertEqual(events.map(\.eventType), [.paymentThreeds])
        XCTAssertNil(events.first?.metadata?.paymentMethod)
        XCTAssertEqual(events.first?.metadata?.threedsProvider, "PROCESSOR")
    }
}
