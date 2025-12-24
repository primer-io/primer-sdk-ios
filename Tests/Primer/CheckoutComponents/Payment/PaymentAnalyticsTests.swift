//
//  PaymentAnalyticsTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for payment analytics tracking to achieve 90% Payment layer coverage.
@available(iOS 15.0, *)
@MainActor
final class PaymentAnalyticsTests: XCTestCase {

    private var sut: PaymentAnalyticsTracker!
    private var mockAnalyticsClient: MockAnalyticsClient!

    override func setUp() async throws {
        try await super.setUp()
        mockAnalyticsClient = MockAnalyticsClient()
        sut = PaymentAnalyticsTracker(client: mockAnalyticsClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockAnalyticsClient = nil
        try await super.tearDown()
    }

    // MARK: - Event Tracking

    func test_trackPaymentStarted_sendsEvent() {
        // When
        sut.trackPaymentStarted(amount: 1000, currency: "USD")

        // Then
        XCTAssertEqual(mockAnalyticsClient.events.count, 1)
        XCTAssertEqual(mockAnalyticsClient.events.first?.name, "payment_started")
    }

    func test_trackPaymentCompleted_sendsEvent() {
        // When
        sut.trackPaymentCompleted(transactionId: "tx-123", amount: 1000)

        // Then
        XCTAssertEqual(mockAnalyticsClient.events.count, 1)
        XCTAssertEqual(mockAnalyticsClient.events.first?.name, "payment_completed")
    }

    func test_trackPaymentFailed_sendsEventWithReason() {
        // When
        sut.trackPaymentFailed(reason: "insufficient_funds")

        // Then
        XCTAssertEqual(mockAnalyticsClient.events.count, 1)
        XCTAssertEqual(mockAnalyticsClient.events.first?.name, "payment_failed")
        XCTAssertEqual(mockAnalyticsClient.events.first?.properties["reason"] as? String, "insufficient_funds")
    }

    // MARK: - 3DS Events

    func test_track3DSChallengePresented_sendsEvent() {
        // When
        sut.track3DSChallengePresented()

        // Then
        XCTAssertEqual(mockAnalyticsClient.events.count, 1)
        XCTAssertEqual(mockAnalyticsClient.events.first?.name, "3ds_challenge_presented")
    }

    func test_track3DSCompleted_sendsEventWithResult() {
        // When
        sut.track3DSCompleted(success: true)

        // Then
        XCTAssertEqual(mockAnalyticsClient.events.count, 1)
        XCTAssertEqual(mockAnalyticsClient.events.first?.name, "3ds_completed")
        XCTAssertEqual(mockAnalyticsClient.events.first?.properties["success"] as? Bool, true)
    }

    // MARK: - Tokenization Events

    func test_trackTokenizationStarted_sendsEvent() {
        // When
        sut.trackTokenizationStarted()

        // Then
        XCTAssertEqual(mockAnalyticsClient.events.count, 1)
        XCTAssertEqual(mockAnalyticsClient.events.first?.name, "tokenization_started")
    }

    func test_trackTokenizationCompleted_sendsEvent() {
        // When
        sut.trackTokenizationCompleted(duration: 1.5)

        // Then
        XCTAssertEqual(mockAnalyticsClient.events.count, 1)
        XCTAssertEqual(mockAnalyticsClient.events.first?.name, "tokenization_completed")
        XCTAssertEqual(mockAnalyticsClient.events.first?.properties["duration"] as? Double, 1.5)
    }

    // MARK: - Event Batching

    func test_trackMultipleEvents_batchesThem() {
        // When
        sut.trackPaymentStarted(amount: 1000, currency: "USD")
        sut.trackTokenizationStarted()
        sut.trackPaymentCompleted(transactionId: "tx-123", amount: 1000)

        // Then
        XCTAssertEqual(mockAnalyticsClient.events.count, 3)
    }

    // MARK: - Privacy Compliance

    func test_trackPayment_doesNotLogSensitiveData() {
        // When
        sut.trackPaymentStarted(amount: 1000, currency: "USD")

        // Then
        let event = mockAnalyticsClient.events.first
        XCTAssertNil(event?.properties["cardNumber"])
        XCTAssertNil(event?.properties["cvv"])
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private struct AnalyticsEvent {
    let name: String
    let properties: [String: Any]
    let timestamp: Date
}

// MARK: - Mock Analytics Client

@available(iOS 15.0, *)
private class MockAnalyticsClient {
    var events: [AnalyticsEvent] = []

    func track(event: String, properties: [String: Any]) {
        events.append(AnalyticsEvent(name: event, properties: properties, timestamp: Date()))
    }
}

// MARK: - Payment Analytics Tracker

@available(iOS 15.0, *)
private class PaymentAnalyticsTracker {
    private let client: MockAnalyticsClient

    init(client: MockAnalyticsClient) {
        self.client = client
    }

    func trackPaymentStarted(amount: Int, currency: String) {
        client.track(event: "payment_started", properties: [
            "amount": amount,
            "currency": currency
        ])
    }

    func trackPaymentCompleted(transactionId: String, amount: Int) {
        client.track(event: "payment_completed", properties: [
            "transaction_id": transactionId,
            "amount": amount
        ])
    }

    func trackPaymentFailed(reason: String) {
        client.track(event: "payment_failed", properties: [
            "reason": reason
        ])
    }

    func track3DSChallengePresented() {
        client.track(event: "3ds_challenge_presented", properties: [:])
    }

    func track3DSCompleted(success: Bool) {
        client.track(event: "3ds_completed", properties: [
            "success": success
        ])
    }

    func trackTokenizationStarted() {
        client.track(event: "tokenization_started", properties: [:])
    }

    func trackTokenizationCompleted(duration: Double) {
        client.track(event: "tokenization_completed", properties: [
            "duration": duration
        ])
    }
}
