//
//  RawDataManagerValidationTests.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 1/6/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

@testable import PrimerSDK
import XCTest

final class RawDataManagerValidationTests: XCTestCase {
    private static let ExpectationTimeout = 3.0

    var rawDataManager: RawDataManager!

    var delegate: MockRawDataManagerDelegate!

    static let mockApiClient = MockPrimerAPIClient()

    // MARK: Per-test setUp and tearDown

    override func setUp() {
        delegate = MockRawDataManagerDelegate()
    }

    override func tearDown() {
        delegate = nil
        rawDataManager = nil
    }

    // MARK: suite-wide setUp and tearDown

    override class func setUp() {
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock-client-session-id-1",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
                orderedAllowedCardNetworks: [
                    CardNetwork.visa.rawValue,
                    CardNetwork.masterCard.rawValue,
                    CardNetwork.amex.rawValue
                    //                    ,
                    //                    CardNetwork.unknown.rawValue
                ]
            ),
            order: ClientSession.Order(
                id: "mock-client-session-order-id-1",
                merchantAmount: nil,
                totalOrderAmount: 100,
                totalTaxAmount: nil,
                countryCode: .gb,
                currencyCode: CurrencyLoader().getCurrency("GBP"),
                fees: nil,
                lineItems: [
                    ClientSession.Order.LineItem(
                        itemId: "mock-item-id-1",
                        quantity: 1,
                        amount: 100,
                        discountAmount: nil,
                        name: "mock-name-1",
                        description: "mock-description-1",
                        taxAmount: nil,
                        taxCode: nil,
                        productType: nil
                    )
                ]
            ),
            customer: nil,
            testId: nil
        )

        let mockPrimerApiConfiguration = Response.Body.Configuration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            binDataUrl: "https://primer.io/bindata",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: clientSession,
            paymentMethods: [
                PrimerPaymentMethod(
                    id: "mock-id-1",
                    implementationType: .webRedirect,
                    type: "PAYMENT_CARD",
                    name: "Giropay",
                    processorConfigId: "mock-processor-config-id-1",
                    surcharge: nil,
                    options: nil,
                    displayMetadata: nil
                )
            ],
            primerAccountId: "mock-primer-account-id",
            keys: nil,
            checkoutModules: nil
        )

        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])

        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        mockApiClient.listCardNetworksResult = (Mocks.listCardNetworksData, nil)
        PrimerAPIConfigurationModule.apiClient = mockApiClient
    }

    override class func tearDown() {
        mockApiClient.fetchVaultedPaymentMethodsResult = nil
        mockApiClient.fetchConfigurationResult = nil
        mockApiClient.listCardNetworksResult = nil
        PrimerAPIConfigurationModule.apiClient = nil
    }

    // MARK: Tests

    func test_expectation_callback_invalidData() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 4, "Should have thrown 4 errors")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            XCTAssertEqual((errors?[1] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            XCTAssertEqual((errors?[2] as? PrimerValidationError)?.errorId, "invalid-cvv")
            XCTAssertEqual((errors?[3] as? PrimerValidationError)?.errorId, "invalid-cardholder-name")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid data
        let cardData = PrimerCardData(cardNumber: "",
                                      expiryDate: "",
                                      cvv: "",
                                      cardholderName: nil)
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidData_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 4, "Should have thrown 4 errors")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            XCTAssertEqual((errors?[1] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            XCTAssertEqual((errors?[2] as? PrimerValidationError)?.errorId, "invalid-cvv")
            XCTAssertEqual((errors?[3] as? PrimerValidationError)?.errorId, "invalid-cardholder-name")
            expectation.fulfill()
        }

        // Invalid data
        let cardData = PrimerCardData(cardNumber: "",
                                      expiryDate: "",
                                      cvv: "",
                                      cardholderName: nil)
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_validData() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertTrue(isValid, "Data should be valid")
            XCTAssertNil(errors, "Should not have thrown errors")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Valid data
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_validData_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertTrue(isValid, "Data should be valid")
            XCTAssertNil(errors, "Should not have thrown errors")
            expectation.fulfill()
        }

        // Valid data
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCardNumberLengthShort() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be valid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "424242424242424",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCardNumberLengthShort_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            expectation.fulfill()
        }

        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "424242424242424",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCardNumberLengthLong() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be valid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "42424242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCardNumberLengthLong_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            expectation.fulfill()
        }

        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "42424242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCardNumberEmpty() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be valid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCardNumberEmpty_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            expectation.fulfill()
        }

        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCardNumberLuhnFailure() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be valid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "4242424242424243",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCardNumberLuhnFailure_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            expectation.fulfill()
        }

        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "4242424242424243",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateMonthInvalid() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be valid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "0/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateMonthInvalid_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "0/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateMonthMissing() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be valid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateMonthMissing_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateMonth() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be valid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateMonth_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateInvalid() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be valid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "/",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateInvalid_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "/",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDatePast() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be valid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "01/2022",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDatePast_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "01/2022",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDatePast2() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be valid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "05/2022",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDatePast2_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "01/2022",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateMonthOnly() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "02",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateMonthOnly_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "02",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateNonNumeric() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "aa",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateNonNumeric_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "aa",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateOrder() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "2030/03",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateOrder_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "2030/03",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateYearShort() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/30",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateYearShort_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/30",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateYearMalformed() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/203030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidExpiryDateYearMalformed_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            expectation.fulfill()
        }

        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/203030",
                                      cvv: "123",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCVVLengthShort() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "12",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCVVLengthShort_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            expectation.fulfill()
        }

        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "12",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCVVNonNumeric() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "abc",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCVVNonNumeric_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            expectation.fulfill()
        }

        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "abc",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCVVLengthLong() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "12345",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCVVLengthLong_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            expectation.fulfill()
        }

        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "12345",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCVVLengthShorter() throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        setupRawDataManager()

        firstly {
            self.validateWithRawDataManager()
        }
        .done { isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }

        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "1",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData
        wait(for: [expectation], timeout: Self.ExpectationTimeout)
    }

    func test_expectation_callback_invalidCVVLengthShorter_async() async throws {
        let expectation = XCTestExpectation(description: "Callback should be called")
        try await setupRawDataManager_async()

        delegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            expectation.fulfill()
        }

        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "1",
                                      cardholderName: "Test")
        rawDataManager.rawData = cardData

        await fulfillment(of: [expectation], timeout: Self.ExpectationTimeout)
    }
}

extension RawDataManagerValidationTests {
    // MARK: Helpers

    private func setupRawDataManager() {
        let startHeadlessExpectation = XCTestExpectation(description: "Start Headless Universal Checkout")
        let expectationsToBeFulfilled = [startHeadlessExpectation]

        firstly {
            self.startHeadlessUniversalCheckout(clientToken: MockAppState.mockClientToken)
        }
        .done { _ in
            startHeadlessExpectation.fulfill()
        }
        .catch { _ in
            XCTAssert(true, "Raw Data Manager should had been initialized")
            startHeadlessExpectation.fulfill()
        }

        wait(for: expectationsToBeFulfilled, timeout: 30)

        do {
            let paymentMethodType = "PAYMENT_CARD"
            rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethodType)
            rawDataManager.delegate = delegate
            rawDataManager.tokenizationService = TokenizationService(apiClient: Self.mockApiClient)

            let rawDataTokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: paymentMethodType)
            rawDataTokenizationBuilder.rawDataManager = rawDataManager
            rawDataTokenizationBuilder.cardValidationService = nil

            rawDataManager.rawDataTokenizationBuilder = rawDataTokenizationBuilder
        } catch {
            print("ERROR: \(error.localizedDescription)")
            XCTAssert(false, "Raw Data Manager should had been initialized")
        }
    }

    private func setupRawDataManager_async() async throws {
        _ = try await PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken)

        let paymentMethodType = "PAYMENT_CARD"
        rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethodType)
        rawDataManager.delegate = delegate
        rawDataManager.tokenizationService = TokenizationService(apiClient: Self.mockApiClient)

        let rawDataTokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: paymentMethodType)
        rawDataTokenizationBuilder.rawDataManager = rawDataManager
        rawDataTokenizationBuilder.cardValidationService = nil

        rawDataManager.rawDataTokenizationBuilder = rawDataTokenizationBuilder
    }

    func startHeadlessUniversalCheckout(clientToken: String) -> Promise<[PrimerHeadlessUniversalCheckout.PaymentMethod]> {
        return Promise { seal in
            PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken) { paymentMethods, err in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethods = paymentMethods {
                    seal.fulfill(paymentMethods)
                }
            }
        }
    }

    func validateWithRawDataManager() -> Promise<(isValid: Bool, errors: [Error]?)> {
        return Promise { seal in
            self.delegate.onDataIsValid = { _, isValid, errors in
                seal.fulfill((isValid, errors))
            }
        }
    }
}
