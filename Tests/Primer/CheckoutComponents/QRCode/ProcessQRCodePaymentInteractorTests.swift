//
//  ProcessQRCodePaymentInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ProcessQRCodePaymentInteractorTests: XCTestCase {

    private var mockRepository: MockQRCodeRepository!
    private var sut: ProcessQRCodePaymentInteractorImpl!

    override func setUp() {
        super.setUp()
        mockRepository = MockQRCodeRepository()
        sut = ProcessQRCodePaymentInteractorImpl(
            repository: mockRepository,
            paymentMethodType: QRCodeTestData.Constants.paymentMethodType
        )
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - startPayment

    func test_startPayment_delegatesToRepositoryWithCorrectType() async throws {
        mockRepository.startPaymentResult = .success(QRCodeTestData.defaultPaymentData)

        let result = try await sut.startPayment()

        XCTAssertEqual(mockRepository.startPaymentCallCount, 1)
        XCTAssertEqual(mockRepository.lastStartPaymentMethodType, QRCodeTestData.Constants.paymentMethodType)
        XCTAssertEqual(result.paymentId, QRCodeTestData.Constants.paymentId)
        XCTAssertEqual(result.statusUrl, QRCodeTestData.Constants.statusUrl)
    }

    func test_startPayment_propagatesRepositoryError() async {
        mockRepository.startPaymentResult = .failure(
            PrimerError.invalidValue(key: "config", value: nil, reason: "Not found")
        )

        do {
            _ = try await sut.startPayment()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - pollAndComplete

    func test_pollAndComplete_pollsThenResumesWithCorrectParameters() async throws {
        mockRepository.pollResult = .success(QRCodeTestData.Constants.resumeToken)
        mockRepository.resumePaymentResult = .success(QRCodeTestData.successPaymentResult)

        let result = try await sut.pollAndComplete(
            statusUrl: QRCodeTestData.Constants.statusUrl,
            paymentId: QRCodeTestData.Constants.paymentId
        )

        XCTAssertEqual(mockRepository.pollForCompletionCallCount, 1)
        XCTAssertEqual(mockRepository.lastPollStatusUrl, QRCodeTestData.Constants.statusUrl)
        XCTAssertEqual(mockRepository.resumePaymentCallCount, 1)
        XCTAssertEqual(mockRepository.lastResumePaymentId, QRCodeTestData.Constants.paymentId)
        XCTAssertEqual(mockRepository.lastResumeToken, QRCodeTestData.Constants.resumeToken)
        XCTAssertEqual(mockRepository.lastResumePaymentMethodType, QRCodeTestData.Constants.paymentMethodType)
        XCTAssertEqual(result.status, .success)
    }

    func test_pollAndComplete_pollingError_doesNotCallResume() async {
        mockRepository.pollResult = .failure(
            PrimerError.cancelled(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
        )

        do {
            _ = try await sut.pollAndComplete(
                statusUrl: QRCodeTestData.Constants.statusUrl,
                paymentId: QRCodeTestData.Constants.paymentId
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
            XCTAssertEqual(mockRepository.pollForCompletionCallCount, 1)
            XCTAssertEqual(mockRepository.resumePaymentCallCount, 0)
        }
    }

    func test_pollAndComplete_resumeError_propagates() async {
        mockRepository.pollResult = .success(QRCodeTestData.Constants.resumeToken)
        mockRepository.resumePaymentResult = .failure(TestError.networkFailure)

        do {
            _ = try await sut.pollAndComplete(
                statusUrl: QRCodeTestData.Constants.statusUrl,
                paymentId: QRCodeTestData.Constants.paymentId
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
            XCTAssertEqual(mockRepository.pollForCompletionCallCount, 1)
            XCTAssertEqual(mockRepository.resumePaymentCallCount, 1)
        }
    }

    // MARK: - cancelPolling

    func test_cancelPolling_delegatesToRepositoryWithCorrectType() {
        sut.cancelPolling()

        XCTAssertEqual(mockRepository.cancelPollingCallCount, 1)
        XCTAssertEqual(mockRepository.lastCancelPaymentMethodType, QRCodeTestData.Constants.paymentMethodType)
    }
}
