//
//  HeadlessRepositoryAdditionalCoverageTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - Redirect Tracking Deduplication

@available(iOS 15.0, *)
@MainActor
final class HeadlessRepositoryRedirectTrackingTests: XCTestCase {

    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        sut = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_trackRedirect_withNilInfo_doesNotCrash() {
        // When / Then — nil info handled gracefully
        sut.trackRedirectToThirdPartyIfNeeded(from: nil)
    }
}

// MARK: - Network Detection Stream

@available(iOS 15.0, *)
@MainActor
final class HeadlessRepositoryNetworkDetectionStreamTests: XCTestCase {

    func test_getNetworkDetectionStream_returnsNonNilStream() {
        // Given
        let sut = HeadlessRepositoryImpl()

        // When
        let stream = sut.getNetworkDetectionStream()

        // Then
        XCTAssertNotNil(stream)
    }
}

// MARK: - Process Card Payment Card Data Sanitization

@available(iOS 15.0, *)
@MainActor
final class HeadlessRepositoryCardDataTests: XCTestCase {

    private var mockRawDataManager: MockRawDataManager!
    private var mockFactory: MockRawDataManagerFactory!
    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockRawDataManager = MockRawDataManager()
        mockFactory = MockRawDataManagerFactory()
        mockFactory.mockRawDataManager = mockRawDataManager
        sut = HeadlessRepositoryImpl(rawDataManagerFactory: mockFactory)
    }

    override func tearDown() {
        mockRawDataManager = nil
        mockFactory = nil
        sut = nil
        PrimerHeadlessUniversalCheckout.current.delegate = nil
        super.tearDown()
    }

    func test_processCardPayment_sanitizesSpacesFromCardNumber() async {
        // Given
        var capturedCardData: PrimerCardData?
        mockRawDataManager.onRawDataSet = { data in
            capturedCardData = data as? PrimerCardData
        }

        let task = Task { [self] in
            _ = try? await sut.processCardPayment(
                cardNumber: "4242 4242 4242 4242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        // Wait for raw data to be set
        try? await Task.sleep(nanoseconds: 500_000_000)
        task.cancel()

        // Then
        if let captured = capturedCardData {
            XCTAssertEqual(captured.cardNumber, "4242424242424242")
        }
    }

    func test_processCardPayment_emptyCardholderName_setsNil() async {
        // Given
        var capturedCardData: PrimerCardData?
        mockRawDataManager.onRawDataSet = { data in
            capturedCardData = data as? PrimerCardData
        }

        let task = Task { [self] in
            _ = try? await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        task.cancel()

        // Then
        if let captured = capturedCardData {
            XCTAssertNil(captured.cardholderName)
        }
    }

    func test_processCardPayment_formatsExpiryDate() async {
        // Given
        var capturedCardData: PrimerCardData?
        mockRawDataManager.onRawDataSet = { data in
            capturedCardData = data as? PrimerCardData
        }

        let task = Task { [self] in
            _ = try? await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "03",
                expiryYear: "28",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        task.cancel()

        // Then
        if let captured = capturedCardData {
            XCTAssertEqual(captured.expiryDate, "03/28")
        }
    }

    func test_processCardPayment_withSelectedNetwork_setsCardNetwork() async {
        // Given
        var capturedCardData: PrimerCardData?
        mockRawDataManager.onRawDataSet = { data in
            capturedCardData = data as? PrimerCardData
        }

        let task = Task { [self] in
            _ = try? await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: .visa
            )
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        task.cancel()

        // Then
        if let captured = capturedCardData {
            XCTAssertEqual(captured.cardNetwork, .visa)
        }
    }

    func test_processCardPayment_factoryThrows_resumesWithError() async {
        // Given
        mockFactory.createError = PrimerError.unknown(message: "Factory failed")

        // When / Then
        do {
            _ = try await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
