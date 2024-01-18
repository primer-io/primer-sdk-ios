//
//  RawDataManagerTests.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 1/6/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class RawDataManagerTests: XCTestCase {
    
    private static let validationTimeout = 1.0
    
    var rawDataManager: RawDataManager!
    
    var delegate: MockRawDataManagerDelegate!

    // MARK: Per-test setUp and tearDown
    
    override func setUp() {
        delegate = MockRawDataManagerDelegate()
        setupRawDataManager()
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
                currencyCode: .GBP,
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
                        taxCode: nil)
                ],
                shippingAmount: nil),
            customer: nil,
            testId: nil)
        
        let mockPrimerApiConfiguration = Response.Body.Configuration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            binDataUrl: "https://primer.io/bindata",
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
        
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        mockApiClient.listCardNetworksResult = (Mocks.listCardNetworksData, nil)
        VaultService.apiClient = mockApiClient
        DefaultCardValidationService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient
    }
    
    override class func tearDown() {
        VaultService.apiClient = nil
        DefaultCardValidationService.apiClient = nil
        PrimerAPIConfigurationModule.apiClient = nil
    }
    
    // MARK: Tests
    
    func test_validation_callback_invalidData() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 5, "Should have thrown 5 errors")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            XCTAssertEqual((errors?[1] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            XCTAssertEqual((errors?[2] as? PrimerValidationError)?.errorId, "unsupported-card-type")
            XCTAssertEqual((errors?[3] as? PrimerValidationError)?.errorId, "invalid-cvv")
            XCTAssertEqual((errors?[4] as? PrimerValidationError)?.errorId, "invalid-cardholder-name")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid data
        let cardData = PrimerCardData(cardNumber: "",
                                      expiryDate: "",
                                      cvv: "",
                                      cardholderName: nil)
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
    }
    
    func test_validation_callback_validData() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertTrue(isValid, "Data should be valid")
            XCTAssertNil(errors, "Should not have thrown errors")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Valid data
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                  expiryDate: "03/2030",
                                  cvv: "123",
                                  cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
    }
    
    func test_validation_callback_invalidCardNumberLengthShort() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(false, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "424242424242424",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidCardNumberLengthLong() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(false, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "42424242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
    }
    
    func test_validation_callback_invalidCardNumberEmpty() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(false, "Data should be invalid")
            XCTAssertEqual(errors?.count, 2, "Should have thrown 2 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            XCTAssertEqual((errors?[1] as? PrimerValidationError)?.errorId, "unsupported-card-type")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidCardNumberLuhnFailure() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(false, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-card-number")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "4242424242424243",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidExpiryDateMonthInvalid() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(false, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "0/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidExpiryDateMonthMissing() throws {
        setupRawDataManager()
        
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(false, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
    }
    
    func test_validation_callback_invalidExpiryDateMonth() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(false, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidExpiryDateInvalid() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(false, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "/",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
    }
    
    func test_validation_callback_invalidExpiryDatePast() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(false, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "01/2022",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidExpiryDatePast2() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(false, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "05/2022",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidExpiryDateMonthOnly() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "02",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidExpiryDateNonNumeric() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "aa",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidExpiryDateOrder() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            validation.fulfill()
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "2030/03",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidExpiryDateYearShort() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/30",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidExpiryDateYearMalformed() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid expiry date
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/203030",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidCVVLengthShort() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "12",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidCVVNonNumeric() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "abc",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidCVVLengthLong() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "12345",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidCVVLengthShorter() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "invalid-cvv")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "4242424242424242",
                                      expiryDate: "03/2030",
                                      cvv: "1",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidCardNetwork() throws {
        let validation = self.expectation(description: "Await validation")
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "unsupported-card-type")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "9120000000000006",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test",
                                      cardNetwork: .diners)
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidCardNetwork2() throws {
        let validation = self.expectation(description: "Await validation")

        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(isValid, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 1 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "unsupported-card-type")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid CVV
        let cardData = PrimerCardData(cardNumber: "9120000000000006",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test",
                                      cardNetwork: .maestro)
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func test_validation_callback_invalidCardNetwork3() throws {
        let validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssertFalse(false, "Data should be invalid")
            XCTAssertEqual(errors?.count, 1, "Should have thrown 2 error")
            XCTAssertEqual((errors?[0] as? PrimerValidationError)?.errorId, "unsupported-card-type")
            validation.fulfill()
        }
        .catch { _ in
            XCTFail()
        }
        
        // Invalid cardnumber
        let cardData = PrimerCardData(cardNumber: "1800111122223337",
                                      expiryDate: "03/2030",
                                      cvv: "123",
                                      cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
}

extension RawDataManagerTests {
    
    // MARK: Helpers
    
    private func setupRawDataManager() {
        let startHeadlessExpectation = expectation(description: "Start Headless Universal Checkout")
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
            self.rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: "PAYMENT_CARD")
            self.rawDataManager.delegate = delegate
        } catch {
            XCTAssert(false, "Raw Data Manager should had been initialized")
        }
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
            self.delegate.onDataIsValid = { (_, isValid, errors) in
                seal.fulfill((isValid, errors))
            }
        }
    }
}
