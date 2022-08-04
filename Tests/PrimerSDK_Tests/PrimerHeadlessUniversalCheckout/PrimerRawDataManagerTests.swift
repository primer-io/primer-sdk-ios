//
//  PrimerRawDataManagerTests.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 12/7/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class PrimerRawDataManagerTests: XCTestCase {
    
    fileprivate var didCompleteCheckout: ((_ data: PrimerCheckoutData) -> Void)?
    
    func test_initialize_primer_raw_data_manager() throws {
        var paymentMethodType: String!
        
        do {
            paymentMethodType = PrimerPaymentMethodType.adyenBlik.rawValue
            let _ = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethodType)
            paymentMethodType = PrimerPaymentMethodType.payPal.rawValue
            let _ = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethodType)
            paymentMethodType = PrimerPaymentMethodType.applePay.rawValue
            let _ = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethodType)
            paymentMethodType = PrimerPaymentMethodType.buckarooIdeal.rawValue
            let _ = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethodType)
            paymentMethodType = PrimerPaymentMethodType.payNLGiropay.rawValue
            let _ = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethodType)
            
        } catch {
            if !error.localizedDescription.starts(with: "[unsupported-payment-method-type] Unsupported payment method type \(paymentMethodType)") {
                throw error
            }
        }
        
        do {
            paymentMethodType = PrimerPaymentMethodType.paymentCard.rawValue
            let _ = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethodType)
            
        } catch {
            throw error
        }
    }
    
    func test_list_primer_payment_method_types() throws {
        let apiClient = MockPrimerAPIClient()
        
        let validateClientTokenData = try! JSONEncoder().encode(SuccessResponse(success: true))
        apiClient.validateClientTokenResponse = validateClientTokenData
        DependencyContainer.register(apiClient as PrimerAPIClientProtocol)
        
        let expectation = self.expectation(description: "Fetch payment method types")
        
        var paymentMethodTypes: [String]?
        
        PrimerHeadlessUniversalCheckout.current.delegate = self
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken) { pmts, err in
            paymentMethodTypes = pmts
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        if !(paymentMethodTypes ?? []).contains(PrimerPaymentMethodType.paymentCard.rawValue) ||
            !(paymentMethodTypes ?? []).contains(PrimerPaymentMethodType.applePay.rawValue) ||
            !(paymentMethodTypes ?? []).contains(PrimerPaymentMethodType.adyenGiropay.rawValue)
        {
            XCTAssert(false, "Failed to fetch mocked payment method types")
        }
    }
    
    func test_list_primer_input_elements() throws {
        let primerAPIConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://primer.core.url",
            pciUrl: "https://primer.pci.url",
            clientSession: nil,
            paymentMethods: nil,
            keys: nil,
            checkoutModules: nil)
        MockLocator.registerDependencies()
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        state.apiConfiguration = primerAPIConfiguration
        
        let inputElementTypes = PrimerHeadlessUniversalCheckout.current.listRequiredInputElementTypes(for: PrimerPaymentMethodType.paymentCard.rawValue)
        
        if inputElementTypes?.count != 3 {
            XCTAssert(false, "List required input element types should contain 3 elements")
        }
        
        if (inputElementTypes?.contains(.cardNumber) ?? false) == false {
            XCTAssert(false, "List required input element types should contain .cardNumber")
        }
        
        if (inputElementTypes?.contains(.expiryDate) ?? false) == false {
            XCTAssert(false, "List required input element types should contain .expiryDate")
        }
        
        if (inputElementTypes?.contains(.cvv) ?? false) == false {
            XCTAssert(false, "List required input element types should contain .cvv")
        }
    }
    
    func test_validate_invalid_raw_data() throws {
        let rawDataManager = try! PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue)
        
        var expectation = self.expectation(description: "Validate empty raw card data")
        
        var testData: PrimerRawData = PrimerCardData(
            number: "",
            expiryMonth: "",
            expiryYear: "",
            cvv: "",
            cardholderName: nil)
        
        firstly {
            rawDataManager.validateRawData(testData)
        }
        .done {
            XCTAssert(false, "Primer SDK validated wrong data")
            expectation.fulfill()
        }
        .catch { err in
            if let primerErr = err as? PrimerError,
               case .underlyingErrors = primerErr,
               primerErr.localizedDescription.contains("[invalid-cardnumber]"),
               primerErr.localizedDescription.contains("[invalid-expiry-date]"),
               primerErr.localizedDescription.contains("[invalid-cvv]") {
                XCTAssert(true, "Primer SDK threw correct error")
                
            } else {
                XCTAssert(false, "Primer SDK threw wrong error")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        expectation = self.expectation(description: "Validate wrong card number")
        
        testData = PrimerCardData(
            number: "4242424242424241",
            expiryMonth: "02",
            expiryYear: "2024",
            cvv: "123",
            cardholderName: nil)
        
        firstly {
            rawDataManager.validateRawData(testData)
        }
        .done {
            XCTAssert(false, "Primer SDK validated wrong data")
            expectation.fulfill()
        }
        .catch { err in
            if let primerErr = err as? PrimerError,
               case .underlyingErrors = primerErr,
               primerErr.localizedDescription.contains("[invalid-cardnumber]"),
               !primerErr.localizedDescription.contains("[invalid-expiry-date]"),
               !primerErr.localizedDescription.contains("[invalid-cvv]") {
                XCTAssert(true, "Primer SDK threw correct error")
                
            } else {
                XCTAssert(false, "Primer SDK threw wrong error")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        expectation = self.expectation(description: "Validate wrong expiry date")
        
        testData = PrimerCardData(
            number: "4242424242424242",
            expiryMonth: "02",
            expiryYear: "2020",
            cvv: "123",
            cardholderName: nil)
        
        firstly {
            rawDataManager.validateRawData(testData)
        }
        .done {
            XCTAssert(false, "Primer SDK validated wrong expiry date")
            expectation.fulfill()
        }
        .catch { err in
            if let primerErr = err as? PrimerError,
               case .underlyingErrors = primerErr,
               !primerErr.localizedDescription.contains("[invalid-cardnumber]"),
               primerErr.localizedDescription.contains("[invalid-expiry-date]"),
               !primerErr.localizedDescription.contains("[invalid-cvv]") {
                XCTAssert(true, "Primer SDK threw correct error")
                
            } else {
                XCTAssert(false, "Primer SDK threw wrong error")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        expectation = self.expectation(description: "Validate wrong CVV")
        
        testData = PrimerCardData(
            number: "4242424242424242",
            expiryMonth: "02",
            expiryYear: "2024",
            cvv: "12",
            cardholderName: nil)
        
        firstly {
            rawDataManager.validateRawData(testData)
        }
        .done {
            XCTAssert(false, "Primer SDK validated wrong CVV")
            expectation.fulfill()
        }
        .catch { err in
            if let primerErr = err as? PrimerError,
               case .underlyingErrors = primerErr,
               !primerErr.localizedDescription.contains("[invalid-cardnumber]"),
               !primerErr.localizedDescription.contains("[invalid-expiry-date]"),
               primerErr.localizedDescription.contains("[invalid-cvv]") {
                XCTAssert(true, "Primer SDK threw correct error")
                
            } else {
                XCTAssert(false, "Primer SDK threw wrong error")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func test_validate_valid_raw_data() throws {
        let rawDataManager = try! PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue)
        
        let testData: PrimerRawData = PrimerCardData(
            number: "4242424242424242",
            expiryMonth: "02",
            expiryYear: "2024",
            cvv: "123",
            cardholderName: nil)
        
        let expectation = self.expectation(description: "Validate correct raw card data")
        
        firstly {
            rawDataManager.validateRawData(testData)
        }
        .done {
            XCTAssert(true, "Primer SDK successfully validated correct raw data")
            expectation.fulfill()
        }
        .catch { err in
            XCTAssert(false, "Primer SDK threw failed to validate correct data with error \(err.localizedDescription)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    func test_submit_data() throws {
        let apiClient = MockPrimerAPIClient()
        
        let validateClientTokenData = try! JSONEncoder().encode(SuccessResponse(success: true))
        apiClient.validateClientTokenResponse = validateClientTokenData
        
        let mockPaymentMethodTokenDataJson: [String: Any] = [
            "paymentInstrumentData" : [
                "last4Digits" : "4242",
                "expirationYear" : "2024",
                "expirationMonth" : "02",
                "isNetworkTokenized" : false,
                "binData" : [
                    "accountFundingType" : "UNKNOWN",
                    "accountNumberType" : "UNKNOWN",
                    "productUsageType" : "UNKNOWN",
                    "productCode" : "UNKNOWN",
                    "productName" : "UNKNOWN",
                    "regionalRestriction" : "UNKNOWN",
                    "prepaidReloadableIndicator" : "NOT_APPLICABLE",
                    "network" : "VISA",
                    "issuerCountryCode" : "US"
                ],
                "network" : "Visa"
            ],
            "isAlreadyVaulted" : false,
            "threeDSecureAuthentication" : [
                "responseCode" : "NOT_PERFORMED"
            ],
            "tokenType" : "SINGLE_USE",
            "isVaulted" : false,
            "token" : "Lgo_qEviS-2PGvlJycW4dnwxNjU3NzA5Njkw",
            "analyticsId" : "5bnKsoCZV9OG1083OXQIQFRo",
            "paymentInstrumentType" : "PAYMENT_CARD"
        ]
        
        let tokenizePaymentMethodResponse = try! JSONSerialization.data(withJSONObject: mockPaymentMethodTokenDataJson)
        apiClient.tokenizePaymentMethodResponse = tokenizePaymentMethodResponse
        
        let mockCreatePaymentResponseJson: [String: Any] = [
            "status" : "SUCCESS",
            "orderId" : "ios_order_id_jrs21gA4",
            "amount" : 101109,
            "id" : "R6NCKw3f",
            "currencyCode" : "GBP",
            "date" : "2022-07-13T11:03:05.069245",
            "customerId" : "ios-customer-K0fMEH0H"
        ]
        
        let createPaymentResponse = try! JSONSerialization.data(withJSONObject: mockCreatePaymentResponseJson)
        apiClient.createPaymentResponse = createPaymentResponse
        
        DependencyContainer.register(apiClient as PrimerAPIClientProtocol)
        
        var expectation = self.expectation(description: "Fetch payment method types")
        
        PrimerHeadlessUniversalCheckout.current.delegate = self
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken) { pmts, err in
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        let rawDataManager = try! PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue)
        
        let testData: PrimerRawData = PrimerCardData(
            number: "4242424242424242",
            expiryMonth: "02",
            expiryYear: "2024",
            cvv: "123",
            cardholderName: nil)
        
        expectation = self.expectation(description: "Validate raw card data")
        
        self.didCompleteCheckout = { checkoutData in
            expectation.fulfill()
        }
        rawDataManager.rawData = testData
        
        rawDataManager.submit()
        
        waitForExpectations(timeout: 30, handler: nil)
    }
}

extension PrimerRawDataManagerTests: PrimerHeadlessUniversalCheckoutDelegate {
    
    func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethodTypes: [String]) {
        
    }
    
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        self.didCompleteCheckout?(data)
    }
}

#endif

