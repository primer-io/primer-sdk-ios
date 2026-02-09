//
//  ProcessBankSelectorPaymentInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ProcessBankSelectorPaymentInteractorTests: XCTestCase {

    // MARK: - Properties

    var sut: ProcessBankSelectorPaymentInteractorImpl!
    var mockRepository: MockBankSelectorRepository!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockBankSelectorRepository()
        sut = ProcessBankSelectorPaymentInteractorImpl(repository: mockRepository)
    }

    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        SDKSessionHelper.tearDown()
        try await super.tearDown()
    }

    // MARK: - fetchBanks Tests

    func test_fetchBanks_mapsAdyenBanksToPublicBanks() async throws {
        // Given
        setupValidConfiguration()

        let adyenBanks = [
            AdyenBank(id: "INGBNL2A", name: "ING Bank", iconUrlStr: "https://example.com/ing.png", disabled: false),
            AdyenBank(id: "RABONL2U", name: "Rabobank", iconUrlStr: nil, disabled: false),
            AdyenBank(id: "DISABLED1", name: "Disabled", iconUrlStr: nil, disabled: true)
        ]
        mockRepository.banksToReturn = adyenBanks

        // When
        let banks = try await sut.fetchBanks(paymentMethodType: PrimerPaymentMethodType.adyenIDeal.rawValue)

        // Then
        XCTAssertEqual(banks.count, 3)
        XCTAssertEqual(banks[0].id, "INGBNL2A")
        XCTAssertEqual(banks[0].name, "ING Bank")
        XCTAssertNotNil(banks[0].iconUrl)
        XCTAssertFalse(banks[0].isDisabled)

        XCTAssertEqual(banks[1].id, "RABONL2U")
        XCTAssertNil(banks[1].iconUrl)

        XCTAssertEqual(banks[2].id, "DISABLED1")
        XCTAssertTrue(banks[2].isDisabled)
    }

    func test_fetchBanks_callsRepositoryWithCorrectPaymentMethod_ideal() async throws {
        // Given
        setupValidConfiguration()
        mockRepository.banksToReturn = []

        // When
        _ = try await sut.fetchBanks(paymentMethodType: PrimerPaymentMethodType.adyenIDeal.rawValue)

        // Then
        XCTAssertEqual(mockRepository.fetchBanksCallCount, 1)
        XCTAssertEqual(mockRepository.lastFetchBanksPaymentMethod, "ideal")
    }

    func test_fetchBanks_callsRepositoryWithCorrectPaymentMethod_dotpay() async throws {
        // Given
        setupDotpayConfiguration()
        mockRepository.banksToReturn = []

        // When
        _ = try await sut.fetchBanks(paymentMethodType: PrimerPaymentMethodType.adyenDotPay.rawValue)

        // Then
        XCTAssertEqual(mockRepository.lastFetchBanksPaymentMethod, "dotpay")
    }

    func test_fetchBanks_propagatesRepositoryError() async throws {
        // Given
        setupValidConfiguration()
        mockRepository.fetchBanksError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.fetchBanks(paymentMethodType: PrimerPaymentMethodType.adyenIDeal.rawValue)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func test_fetchBanks_throwsWhenPaymentMethodNotConfigured() async throws {
        // Given — no configuration set up
        SDKSessionHelper.setUp(withPaymentMethods: [])

        // When/Then
        do {
            _ = try await sut.fetchBanks(paymentMethodType: PrimerPaymentMethodType.adyenIDeal.rawValue)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .unsupportedPaymentMethod = error {
                // Expected
            } else {
                XCTFail("Expected unsupportedPaymentMethod error, got \(error)")
            }
        }
    }

    // MARK: - execute Tests

    func test_execute_delegatesBankIdAndPaymentMethodType() async throws {
        // Given
        setupValidConfiguration()
        mockRepository.paymentResultToReturn = BankSelectorTestData.testPaymentResult

        // When
        _ = try await sut.execute(bankId: "INGBNL2A", paymentMethodType: PrimerPaymentMethodType.adyenIDeal.rawValue)

        // Then
        XCTAssertEqual(mockRepository.tokenizeCallCount, 1)
        XCTAssertEqual(mockRepository.lastTokenizeBankId, "INGBNL2A")
        XCTAssertEqual(mockRepository.lastTokenizePaymentMethodType, PrimerPaymentMethodType.adyenIDeal.rawValue)
    }

    func test_execute_returnsPaymentResult() async throws {
        // Given
        setupValidConfiguration()
        let expectedResult = BankSelectorTestData.testPaymentResult
        mockRepository.paymentResultToReturn = expectedResult

        // When
        let result = try await sut.execute(bankId: "INGBNL2A", paymentMethodType: PrimerPaymentMethodType.adyenIDeal.rawValue)

        // Then
        XCTAssertEqual(result.paymentId, expectedResult.paymentId)
        XCTAssertEqual(result.status, .success)
    }

    func test_execute_propagatesTokenizeError() async throws {
        // Given
        setupValidConfiguration()
        mockRepository.tokenizeError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.execute(bankId: "INGBNL2A", paymentMethodType: PrimerPaymentMethodType.adyenIDeal.rawValue)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    // MARK: - Helpers

    private func setupValidConfiguration() {
        let idealPaymentMethod = Mocks.PaymentMethods.idealPaymentMethod
        SDKSessionHelper.setUp(withPaymentMethods: [idealPaymentMethod])
    }

    private func setupDotpayConfiguration() {
        let dotpayPaymentMethod = Mocks.PaymentMethods.dotpayPaymentMethod
        SDKSessionHelper.setUp(withPaymentMethods: [dotpayPaymentMethod])
    }
}

// MARK: - Mock Payment Methods

private extension Mocks.PaymentMethods {
    static var idealPaymentMethod: PrimerPaymentMethod {
        PrimerPaymentMethod(
            id: "ideal-config-id",
            implementationType: .nativeSdk,
            type: PrimerPaymentMethodType.adyenIDeal.rawValue,
            name: "iDEAL",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
    }

    static var dotpayPaymentMethod: PrimerPaymentMethod {
        PrimerPaymentMethod(
            id: "dotpay-config-id",
            implementationType: .nativeSdk,
            type: PrimerPaymentMethodType.adyenDotPay.rawValue,
            name: "Dotpay",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
    }
}
