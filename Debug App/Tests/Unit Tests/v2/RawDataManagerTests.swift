//
//  RawDataManagerTests.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 1/6/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class RawDataManagerTests: XCTestCase, PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {
    
    private static let validationTimeout = 1.0
    
    var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager!
    
    func test_validation_callback() throws {
        let startHeadlessExpectation = expectation(description: "Start Headless Universal Checkout")
        let expectationsToBeFulfilled = [startHeadlessExpectation]
        
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock-client-session-id-1",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil),
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
                        taxCode: nil,
                        productType: nil)
                ],
                shippingAmount: nil),
            customer: nil,
            testId: nil)
                
        let mockPrimerApiConfiguration = Response.Body.Configuration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
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
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        
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
            self.rawDataManager.delegate = self
        } catch {
            XCTAssert(false, "Raw Data Manager should had been initialized")
        }
        
        // -------------------
        
        var validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 4, "Should have thrown 4 errors")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid data
        var cardData = PrimerCardData(cardNumber: "", expiryDate: "", cvv: "", cardholderName: nil)
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == true, "Data should be valid")
            XCTAssert(errors == nil, "Should not have thrown errors")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Valid data
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "03/2030", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid cardnumber
        cardData = PrimerCardData(cardNumber: "424242424242424", expiryDate: "03/2030", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid cardnumber
        cardData = PrimerCardData(cardNumber: "42424242424242424242", expiryDate: "03/2030", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid cardnumber
        cardData = PrimerCardData(cardNumber: "", expiryDate: "03/2030", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid cardnumber
        cardData = PrimerCardData(cardNumber: "4242424242424243", expiryDate: "03/2030", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid expiry date
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "0/2030", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid expiry date
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "/2030", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid expiry date
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "2030", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid expiry date
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "/", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid expiry date
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "01/2022", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid expiry date
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "05/2022", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid expiry date
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "02", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid expiry date
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "aa", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid expiry date
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "2030/03", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid expiry date
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "03/30", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid expiry date
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "03/203030", cvv: "123", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid CVV
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "03/2030", cvv: "12", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid CVV
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "03/2030", cvv: "12345", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid CVV
        cardData = PrimerCardData(cardNumber: "4242424242424242", expiryDate: "03/2030", cvv: "abc", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid CVV
        cardData = PrimerCardData(cardNumber: "9120000000000006", expiryDate: "03/2030", cvv: "12345", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
        
        // -------------------
        
        validation = self.expectation(description: "Await validation")
        
        firstly {
            self.validateWithRawDataManager()
        }
        .done { (isValid, errors) in
            XCTAssert(isValid == false, "Data should be invalid")
            XCTAssert(errors?.count == 1, "Should have thrown 1 error")
            validation.fulfill()
        }
        .catch { _ in
            XCTAssert(true)
            validation.fulfill()
        }
        
        // Invalid CVV
        cardData = PrimerCardData(cardNumber: "9120000000000006", expiryDate: "03/2030", cvv: "1", cardholderName: "Test")
        self.rawDataManager.rawData = cardData
        wait(for: [validation], timeout: Self.validationTimeout)
    }
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataIsValid isValid: Bool, errors: [Error]?) {
        self.onRawDataManagerValidation?(isValid, errors)
    }
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, metadataDidChange metadata: [String: Any]?) {
        self.onRawDataManagerMetadataChange?(metadata)
    }
    
    var onRawDataManagerValidation: ((_ isValid: Bool, _ errors: [Error]?) -> Void)?
    var onRawDataManagerMetadataChange: ((_ metadata: [String: Any]?) -> Void)?
    
    func validateWithRawDataManager() -> Promise<(isValid: Bool, errors: [Error]?)> {
        return Promise { seal in
            self.onRawDataManagerValidation = { (isValid, errors) in
                seal.fulfill((isValid, errors))
            }
        }
    }
}

extension RawDataManagerTests {
    
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
}
