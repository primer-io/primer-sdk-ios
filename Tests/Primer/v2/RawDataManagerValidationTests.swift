//
//  RawDataManagerValidationTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

class RawDataManagerValidationTests: XCTestCase {

    var rawDataManager: RawDataManager!
    var delegate: MockRawDataManagerDelegate!
    static let mockApiClient = MockPrimerAPIClient()

    // MARK: Per-test setUp and tearDown

    override func setUp() async throws {
        delegate = MockRawDataManagerDelegate()
        await setupRawDataManager()
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
                ],
                descriptor: nil
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
                        productType: nil)
                ]),
            customer: nil,
            testId: nil)

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
                    displayMetadata: nil)
            ],
            primerAccountId: "mock-primer-account-id",
            keys: nil,
            checkoutModules: nil)

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

    func test_validateRawData_withAllInvalidFields_shouldFailWithMultipleErrors()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "",
                                      expiryDate: "",
                                      cvv: "",
                                      cardholderName: nil)

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 5, "Should have thrown 5 errors")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "unsupported-card-type")
            XCTAssertEqual((errors?[1] as? PrimerValidationError)?.errorId, "invalid-card-number")
            XCTAssertEqual((errors?[2] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            XCTAssertEqual((errors?[3] as? PrimerValidationError)?.errorId, "invalid-cvv")
            XCTAssertEqual((errors?[4] as? PrimerValidationError)?.errorId, "invalid-cardholder-name")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withAllValidFields_shouldSucceed()  {
        // Given
        print("1")
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        print("2")
        // When
        let validation = expectation(description: "Await validation")
        print("3")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertTrue(isValid, "Data should be valid")
            XCTAssertNil(errors, "Should not have thrown errors")
            validation.fulfill()
        }
        print("4")
        rawDataManager.rawData = cardData
        print("5")
        wait(for: [validation], timeout: 300.0)
    }

    // MARK: Card Number Validation Tests

    func test_validateRawData_withShortCardNumber_shouldFailWithCardNumberError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "424242424242424",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withLongCardNumber_shouldFailWithCardNumberError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "42424242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withEmptyCardNumber_shouldFailWithCardNumberError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withLuhnFailureCardNumber_shouldFailWithCardNumberError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424243",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    // MARK: Expiry Date Validation Tests

    func test_validateRawData_withInvalidExpiryMonth_shouldFailWithExpiryError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "0/2030",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withMissingExpiryMonth_shouldFailWithExpiryError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "/2030",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withYearOnlyExpiry_shouldFailWithExpiryError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "2030",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withSlashOnlyExpiry_shouldFailWithExpiryError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "/",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withPastExpiryDate_shouldFailWithExpiryError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "01/2022",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withAnotherPastExpiryDate_shouldFailWithExpiryError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "05/2022",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withMonthOnlyExpiry_shouldFailWithExpiryError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "02",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withNonNumericExpiry_shouldFailWithExpiryError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "aa",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withReversedExpiryOrder_shouldFailWithExpiryError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "2030/03",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withShortYearFormat_shouldSucceed()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/30",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertTrue(isValid, "Data should be valid with MM/YY format")
            XCTAssertNil(errors, "Should not have thrown errors")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withMalformedYear_shouldFailWithExpiryError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/203030",
                                      cvv: "123",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    // MARK: CVV Validation Tests

    func test_validateRawData_withShortCVV_shouldFailWithCVVError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "12",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withNonNumericCVV_shouldFailWithCVVError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "abc",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withLongCVV_shouldFailWithCVVError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "12345",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }

    func test_validateRawData_withSingleDigitCVV_shouldFailWithCVVError()  {
        // Given
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "1",
                                      cardholderName: "Test")

        // When
        let validation = expectation(description: "Await validation")
        delegate.onDataIsValid = { [weak self] (_, isValid, errors) in
            self?.delegate.onDataIsValid = nil // Reset to prevent multiple calls
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            validation.fulfill()
        }
        rawDataManager.rawData = cardData
        wait(for: [validation], timeout: 3.0)
    }
}

extension RawDataManagerValidationTests {

    // MARK: Helpers

    private func setupRawDataManager() async {
        do {
            _ = try await startHeadlessUniversalCheckout(clientToken: MockAppState.mockClientToken)
        } catch {
            // Continue with setup even if headless checkout fails
        }

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
            XCTFail("Raw Data Manager should have been initialized: \(error.localizedDescription)")
        }
    }

    private func startHeadlessUniversalCheckout(clientToken: String) async throws -> [PrimerHeadlessUniversalCheckout.PaymentMethod] {
        return try await withCheckedThrowingContinuation { continuation in
            PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken) { paymentMethods, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let paymentMethods = paymentMethods {
                    continuation.resume(returning: paymentMethods)
                }
            }
        }
    }

}
