//
//  CreateResumePaymentServiceTests.swift
//  PrimerSDK_Tests
//
//  Created by Dario Carlomagno on 28/02/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

@testable import PrimerSDK
import XCTest

class CreateResumePaymentServiceTests: XCTestCase {
    
    func test_create_card_payment_service() throws {
        
        let expectation = XCTestExpectation(description: "Create a card payment | Success")

        let cardPaymentCreationResponse = """
        {"paymentId":"cd1dae1d-7451-4f82-ad7e-a919cb4cf75b","date":"2022-03-01T16:26:18.493790","status":"SETTLED","currencyCode":"EUR","orderId":"9f3b87ea-a494-45d7-b24c-e74daf668add","amount":1446,"customerId":"ios_customer_id"}
        """
        
        do {
            let jsonData = Data(cardPaymentCreationResponse.utf8)
            let mockedResponse = try JSONDecoder().decode(Payment.Response.self, from: jsonData)
            let api = MockPrimerAPIClient(with: jsonData, throwsError: false)
            MockLocator.registerDependencies()
            DependencyContainer.register(api as PrimerAPIClientProtocol)

            let service = CreateResumePaymentService()
            service.createPayment(paymentRequest: Payment.CreateRequest(token: "a_payment_method_token")) { response, error in
                
                guard let paymentResponse = response else {
                          if let error = error {
                              XCTAssert(false, error.localizedDescription)
                          }
                          return
                      }
                
                XCTAssertEqual(paymentResponse.status.rawValue, mockedResponse.status.rawValue)

                expectation.fulfill()
            }

            
            XCTAssertEqual(api.isCalled, true)

        } catch {
            XCTAssert(false, error.localizedDescription)
        }
        

        wait(for: [expectation], timeout: 5.0)

    }
    
    func test_create_payment_service() throws {
        
        let expectation = XCTestExpectation(description: "Create a payment | Success")
        
        let paymentCreationResponse = """
{"id":"AUOhM7E6","date":"2022-02-28T18:50:39.707679","amount":5999,"currencyCode":"EUR","customerId":"customer_id","orderId":"ios_order_id_7ZW0onTN","status":"SETTLED","order":{"lineItems":[{"itemId":"_item_id_0","description":"Item","amount":5999,"quantity":1}],"fees":[],"countryCode":"FR"},"customer":{"emailAddress":"john@primer.io","mobileNumber":"+4478888888888","billingAddress":{"firstName":"John","lastName":"Smith","postalCode":"NW06 4OM","addressLine1":"65 York Road","countryCode":"GB","city":"London"},"shippingAddress":{"firstName":"John","lastName":"Smith","postalCode":"EC53 8BT","addressLine1":"9446 Richmond Road","countryCode":"GB","city":"London"}},"paymentMethod":{"paymentMethodToken":"C4TYyAq8Q2aIAopft38LdHwxNjQ2MDc0MjM3","analyticsId":"5bnKsoCZV9OG1083OXQIQFRo","paymentMethodType":"PAYMENT_CARD","paymentMethodData":{"last4Digits":"4242","expirationMonth":"02","expirationYear":"2024","network":"Visa","isNetworkTokenized":false,"binData":{"network":"VISA","issuerCountryCode":"US","regionalRestriction":"UNKNOWN","accountNumberType":"UNKNOWN","accountFundingType":"UNKNOWN","prepaidReloadableIndicator":"NOT_APPLICABLE","productUsageType":"UNKNOWN","productCode":"VISA","productName":"VISA"}},"threeDSecureAuthentication":{"responseCode":"NOT_PERFORMED"}},"processor":{"name":"STRIPE","processorMerchantId":"pk_test_VhbWJUmoI1Bd9auoe1wNqIQr00IFUAFx3M","amountCaptured":5999,"amountRefunded":0},"transactions":[{"transactionType":"SALE","processorTransactionId":"pi_3KYEIvGZqNWFwi8c0RgmnruX","processorName":"STRIPE","processorMerchantId":"pk_test_VhbWJUmoI1Bd9auoe1wNqIQr00IFUAFx3M","processorStatus":"SETTLED"}]}
"""
        
        do {
            let jsonData = Data(paymentCreationResponse.utf8)
            let mockedResponse = try JSONDecoder().decode(Payment.Response.self, from: jsonData)
            let api = MockPrimerAPIClient(with: jsonData, throwsError: false)
            let state = MockAppState()

            DependencyContainer.register(api as PrimerAPIClientProtocol)
            DependencyContainer.register(state as AppStateProtocol)

            let service = CreateResumePaymentService()
            service.createPayment(paymentRequest: Payment.CreateRequest(token: "a_payment_method_token")) { response, error in
                
                guard let paymentResponse = response else {
                          if let error = error {
                              XCTAssert(false, error.localizedDescription)
                          }
                          return
                      }
                
                XCTAssertEqual(paymentResponse.status.rawValue, mockedResponse.status.rawValue)

                expectation.fulfill()
            }

            
            XCTAssertEqual(api.isCalled, true)

        } catch {
            XCTAssert(false, error.localizedDescription)
        }
        

        wait(for: [expectation], timeout: 5.0)
    
    }
    
    func test_resume_payment_service() throws {
        
        let expectation = XCTestExpectation(description: "Resume a payment | Success")
        
        let paymentCreationResponse = """
{"id":"AUOhM7E6","date":"2022-02-28T18:50:39.707679","amount":5999,"currencyCode":"EUR","customerId":"customer_id","orderId":"ios_order_id_7ZW0onTN","status":"SETTLED","order":{"lineItems":[{"itemId":"_item_id_0","description":"Item","amount":5999,"quantity":1}],"fees":[],"countryCode":"FR"},"customer":{"emailAddress":"john@primer.io","mobileNumber":"+4478888888888","billingAddress":{"firstName":"John","lastName":"Smith","postalCode":"NW06 4OM","addressLine1":"65 York Road","countryCode":"GB","city":"London"},"shippingAddress":{"firstName":"John","lastName":"Smith","postalCode":"EC53 8BT","addressLine1":"9446 Richmond Road","countryCode":"GB","city":"London"}},"paymentMethod":{"paymentMethodToken":"C4TYyAq8Q2aIAopft38LdHwxNjQ2MDc0MjM3","analyticsId":"5bnKsoCZV9OG1083OXQIQFRo","paymentMethodType":"PAYMENT_CARD","paymentMethodData":{"last4Digits":"4242","expirationMonth":"02","expirationYear":"2024","network":"Visa","isNetworkTokenized":false,"binData":{"network":"VISA","issuerCountryCode":"US","regionalRestriction":"UNKNOWN","accountNumberType":"UNKNOWN","accountFundingType":"UNKNOWN","prepaidReloadableIndicator":"NOT_APPLICABLE","productUsageType":"UNKNOWN","productCode":"VISA","productName":"VISA"}},"threeDSecureAuthentication":{"responseCode":"NOT_PERFORMED"}},"processor":{"name":"STRIPE","processorMerchantId":"pk_test_VhbWJUmoI1Bd9auoe1wNqIQr00IFUAFx3M","amountCaptured":5999,"amountRefunded":0},"transactions":[{"transactionType":"SALE","processorTransactionId":"pi_3KYEIvGZqNWFwi8c0RgmnruX","processorName":"STRIPE","processorMerchantId":"pk_test_VhbWJUmoI1Bd9auoe1wNqIQr00IFUAFx3M","processorStatus":"SETTLED"}]}
"""
        
        do {
            let jsonData = Data(paymentCreationResponse.utf8)
            let mockedResponse = try JSONDecoder().decode(Payment.Response.self, from: jsonData)
            let api = MockPrimerAPIClient(with: jsonData, throwsError: false)
            let state = MockAppState()

            DependencyContainer.register(api as PrimerAPIClientProtocol)
            DependencyContainer.register(state as AppStateProtocol)

            let service = CreateResumePaymentService()
            service.resumePaymentWithPaymentId("AUOhM7E6", paymentResumeRequest: Payment.ResumeRequest(token: "a_resume_token")) { response, error in
                guard let paymentResponse = response else {
                          if let error = error {
                              XCTAssert(false, error.localizedDescription)
                          }
                          return
                      }
                
                XCTAssertEqual(paymentResponse.status.rawValue, mockedResponse.status.rawValue)

                expectation.fulfill()
            }

            
            XCTAssertEqual(api.isCalled, true)

        } catch {
            XCTAssert(false, error.localizedDescription)
        }
        

        wait(for: [expectation], timeout: 5.0)
    
    }

}
