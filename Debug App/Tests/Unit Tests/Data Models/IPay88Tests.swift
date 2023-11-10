//
//  IPay88Tests.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 19/4/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerIPay88MYSDK)
import XCTest
@testable import PrimerIPay88MYSDK
@testable import PrimerSDK

class IPay88Tests: XCTestCase {
    
    var iPay88Config = PrimerPaymentMethod(
        id: "iPay88-config-id",
        implementationType: .iPay88Sdk,
        type: "",
        name: "iPay88",
        processorConfigId: "processor-config-id",
        surcharge: nil,
        options: MerchantOptions(
            merchantId: "merchant-id",
            merchantAccountId: "merchant-account-id",
            appId: "app-id"),
        displayMetadata: nil)
    
    func test_iPay88_payment_object_mapping() throws {
        var paymentObjects = try self.createIPay88PaymentObjects()
        try self.testMapping(primerIPay88Payment: paymentObjects.0, iPay88Payment: paymentObjects.1, scenario: "All params are valid")
        
        paymentObjects = try self.createIPay88PaymentObjects(userContact: nil)
        try self.testMapping(primerIPay88Payment: paymentObjects.0, iPay88Payment: paymentObjects.1, scenario: "userContact: null")
        
        paymentObjects = try self.createIPay88PaymentObjects(remark: nil)
        try self.testMapping(primerIPay88Payment: paymentObjects.0, iPay88Payment: paymentObjects.1, scenario: "remark: null")
        
        paymentObjects = try self.createIPay88PaymentObjects(lang: nil)
        try self.testMapping(primerIPay88Payment: paymentObjects.0, iPay88Payment: paymentObjects.1, scenario: "lang: null")
        
        paymentObjects = try self.createIPay88PaymentObjects(appdeeplink: nil)
        try self.testMapping(primerIPay88Payment: paymentObjects.0, iPay88Payment: paymentObjects.1, scenario: "appdeeplink: null")
        
        paymentObjects = try self.createIPay88PaymentObjects(tokenId: nil)
        try self.testMapping(primerIPay88Payment: paymentObjects.0, iPay88Payment: paymentObjects.1, scenario: "tokenId: null")
        
        paymentObjects = try self.createIPay88PaymentObjects(promoCode: nil)
        try self.testMapping(primerIPay88Payment: paymentObjects.0, iPay88Payment: paymentObjects.1, scenario: "promoCode: null")
        
        paymentObjects = try self.createIPay88PaymentObjects(fixPaymentId: nil)
        try self.testMapping(primerIPay88Payment: paymentObjects.0, iPay88Payment: paymentObjects.1, scenario: "fixPaymentId: null")
    }
    
    func test_iPay88_validations() throws {
#if canImport(PrimerIPay88MYSDK)
        let decodedClientToken = try DecodedJWTToken.createMock(supportedCurrencyCode: "MYR", supportedCountry: "MY")
        let clientToken = try decodedClientToken.toString()
        
        AppState.current.clientToken = clientToken
        
        AppState.current.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: decodedClientToken.coreUrl,
            pciUrl: decodedClientToken.pciUrl,
            clientSession: ClientSession.APIResponse(
                clientSessionId: "client-session-id",
                paymentMethod: nil,
                order: ClientSession.Order(
                    id: "order-id",
                    merchantAmount: nil,
                    totalOrderAmount: 100,
                    totalTaxAmount: nil,
                    countryCode: .my,
                    currencyCode: .MYR,
                    fees: nil,
                    lineItems: [
                        ClientSession.Order.LineItem(
                            itemId: "item-id",
                            quantity: 1,
                            amount: 100,
                            discountAmount: nil,
                            name: "item-name",
                            description: "item-description",
                            taxAmount: nil,
                            taxCode: nil)
                    ],
                    shippingAmount: nil),
                customer: ClientSession.Customer(
                    id: "customer-id",
                    firstName: "customer-first-name",
                    lastName: "customer-last-name",
                    emailAddress: "customer@primer.io",
                    mobileNumber: "12345678",
                    billingAddress: nil,
                    shippingAddress: nil,
                    taxId: nil
                ),
                testId: nil),
            paymentMethods: [

            ],
            primerAccountId: "primer-account-id",
            keys: nil,
            checkoutModules: nil)
        
        let iPay88TokenizationViewModel = IPay88TokenizationViewModel(config: iPay88Config)
        
        do {
            try iPay88TokenizationViewModel.validate()
            let payment = try iPay88TokenizationViewModel.createPrimerIPay88Payment()
        } catch {
            XCTAssert(false, "[All required data present] Failed with error \(error.localizedDescription)")
        }
        
        AppState.current.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: decodedClientToken.coreUrl,
            pciUrl: decodedClientToken.pciUrl,
            clientSession: ClientSession.APIResponse(
                clientSessionId: "client-session-id",
                paymentMethod: nil,
                order: nil,
                customer: nil,
                testId: nil),
            paymentMethods: [

            ],
            primerAccountId: "primer-account-id",
            keys: nil,
            checkoutModules: nil)
                
        do {
            try iPay88TokenizationViewModel.validate()
            XCTAssert(false, "[Customer data missing] Should have failed the validation")
        } catch {
            if let primerErr = error as? PrimerError,
                case .underlyingErrors(let errors, _, _) = primerErr
            {
                let primerErrors = errors.compactMap({ $0 as? PrimerError })
                let amountError = primerErrors.first(where: { $0.localizedDescription.contains("Invalid client session value") && $0.localizedDescription.contains("amount") })
                let lineItemsError = primerErrors.first(where: { $0.localizedDescription.contains("Invalid client session value") && $0.localizedDescription.contains("order.lineItems") })
                let firstNameError = primerErrors.first(where: { $0.localizedDescription.contains("Invalid client session value") && $0.localizedDescription.contains("customer.firstName") })
                let lastNameError = primerErrors.first(where: { $0.localizedDescription.contains("Invalid client session value") && $0.localizedDescription.contains("customer.lastName") })
                let emailError = primerErrors.first(where: { $0.localizedDescription.contains("Invalid client session value") && $0.localizedDescription.contains("customer.emailAddress") })
                
                XCTAssert(primerErrors.count == 5, "Should have received 3 underlying errors")
                XCTAssert(amountError != nil, "Should have received a amount error")
                XCTAssert(lineItemsError != nil, "Should have received a lineItems error")
                XCTAssert(firstNameError != nil, "Should have received a firstName error")
                XCTAssert(lastNameError != nil, "Should have received a lastName error")
                XCTAssert(emailError != nil, "Should have received an email error")

            } else {
                XCTAssert(false, "[Customer data missing] Should have thrown .underlying errors")
            }
        }
        
        do {
            let payment = try iPay88TokenizationViewModel.createPrimerIPay88Payment()
            XCTAssert(false, "Shoudln't succeed to create payment")
        } catch {
            if let primerError = error as? PrimerError {
                switch primerError {
                case .invalidClientToken:
                    break
                default:
                    XCTAssert(false, error.localizedDescription)
                }
            }
        }
#else
        XCTAssert(false, "PrimerIPay88MYSDK hasn't been imported.")
#endif
    }
    
    // MARK: Helpers
#if canImport(PrimerIPay88MYSDK)
    func createIPay88PaymentObjects(
        merchantCode: String = "merchant-code",
        paymentId: String = "payment-id",
        refNo: String = "primer-transaction-id",
        amount: String = "101",
        currency: String = "MYR",
        prodDesc: String = "product-description",
        userName: String = "user-name",
        userEmail: String = "user@email.com",
        userContact: String? = "1234567890",
        remark: String? = "remark",
        lang: String? = "UTF-8",
        country: String = "MY",
        backendPostURL: String = "https://url.com",
        appdeeplink: String? = "app-deep-link",
        actionType: String? = "1",
        tokenId: String? = "token-id",
        promoCode: String? = "promo-code",
        fixPaymentId: String? = "fix-payment-id",
        transId: String? = "trans-id",
        authCode: String? = "product-description"
    ) throws -> (PrimerIPay88Payment, IpayPayment) {
        let primerIPay88Payment = PrimerIPay88Payment(
            merchantCode: merchantCode,
            paymentId: paymentId,
            refNo: refNo,
            amount: amount,
            currency: currency,
            prodDesc: prodDesc,
            userName: userName,
            userEmail: userEmail,
            userContact: userContact ?? "",
            remark: remark,
            lang: lang,
            country: country,
            backendPostURL: backendPostURL,
            appdeeplink: appdeeplink,
            actionType: actionType,
            tokenId: tokenId,
            promoCode: promoCode,
            fixPaymentId: fixPaymentId,
            transId: transId,
            authCode: authCode)
        
        return (primerIPay88Payment, primerIPay88Payment.iPay88Payment)
    }

    
    func testMapping(primerIPay88Payment: PrimerIPay88Payment, iPay88Payment: IpayPayment, scenario: String) throws {
        XCTAssert(primerIPay88Payment.merchantCode == iPay88Payment.merchantCode, "[Scenario: \(scenario)] merchantCode mismatch")
        XCTAssert(primerIPay88Payment.paymentId == iPay88Payment.paymentId, "[Scenario: \(scenario)] paymentId mismatch")
        XCTAssert(primerIPay88Payment.refNo == iPay88Payment.refNo, "[Scenario: \(scenario)] refNo mismatch")
        XCTAssert(primerIPay88Payment.amount == iPay88Payment.amount, "[Scenario: \(scenario)] amount mismatch")
        XCTAssert(primerIPay88Payment.currency == iPay88Payment.currency, "[Scenario: \(scenario)] currency mismatch")
        XCTAssert(primerIPay88Payment.prodDesc == iPay88Payment.prodDesc, "[Scenario: \(scenario)] prodDesc mismatch")
        XCTAssert(primerIPay88Payment.userName == iPay88Payment.userName, "[Scenario: \(scenario)] userName mismatch")
        XCTAssert(primerIPay88Payment.userEmail == iPay88Payment.userEmail, "[Scenario: \(scenario)] userEmail mismatch")
        XCTAssert(primerIPay88Payment.remark == iPay88Payment.remark, "[Scenario: \(scenario)] remark mismatch")
        XCTAssert(primerIPay88Payment.lang == iPay88Payment.lang, "[Scenario: \(scenario)] lang mismatch")
        XCTAssert(primerIPay88Payment.country == iPay88Payment.country, "[Scenario: \(scenario)] country mismatch")
        XCTAssert(primerIPay88Payment.backendPostURL == iPay88Payment.backendPostURL, "[Scenario: \(scenario)] backendPostURL mismatch")
        XCTAssert(primerIPay88Payment.appdeeplink == iPay88Payment.appdeeplink, "[Scenario: \(scenario)] appdeeplink mismatch")
        XCTAssert(primerIPay88Payment.actionType == iPay88Payment.actionType, "[Scenario: \(scenario)] actionType mismatch")
        XCTAssert("" == iPay88Payment.tokenId, "[Scenario: \(scenario)] tokenId mismatch")
        XCTAssert(primerIPay88Payment.promoCode == iPay88Payment.promoCode, "[Scenario: \(scenario)] promoCode mismatch")
        XCTAssert(primerIPay88Payment.fixPaymentId == iPay88Payment.fixPaymentId, "[Scenario: \(scenario)] fixPaymentId mismatch")
    }
#endif
}

#endif