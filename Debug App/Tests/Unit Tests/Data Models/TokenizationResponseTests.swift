//
//  TokenizationResponseTests.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 21/4/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class TokenizationResponseTests: XCTestCase {
    
    var _tokenizationResponseDictionary: [String: Any] = [
        "analyticsId" : "some-analytics-id",
        "isAlreadyVaulted" : false,
        "isVaulted" : false,
        "paymentInstrumentData": [
            "cardholderName": "John Smith",
            "expirationMonth": "02",
            "expirationYear": "2030",
            "first6Digits": "123456",
            "last4Digits": "1234",
            "isNetworkTokenized": false,
            "klarnaCustomerToken": "some-customer-token",
            "network": "Visa",
            "paymentMethodConfigId" : "some-config-id",
            "paymentMethodType" : "A_PAYMENT_METHOD_TYPE",
            "paypalBillingAgreementId": "some-paypal-agreement-id",
            "sessionData": [
                "recurringDescription": "some-description",
                "purchaseCountry": "GB",
                "purchaseCurrency": "GBP",
                "locale": "en-US",
                "orderAmount": 100,
                "orderLines": [
                    [
                        "type": "some-type",
                        "name": "some-name",
                        "quantity": 1,
                        "unitPrice": 100,
                        "totalAmount": 100,
                        "totalDiscountAmount": 0
                    ] as [String : Any]
                ]
            ] as [String : Any],
            "sessionInfo" : [
              "locale" : "en-US",
              "platform" : "IOS",
              "redirectionUrl" : "primer://some-url.io"
            ]
        ] as [String : Any],
        "paymentInstrumentType" : "OFF_SESSION_PAYMENT",
        "threeDSecureAuthentication" : [
          "responseCode" : "NOT_PERFORMED",
          "reasonCode": "some-reason-code",
          "reasonText": "some-reason-text",
          "protocolVersion": "2.1"
        ],
        "token" : "some-token",
        "tokenType" : "SINGLE_USE",
    ]
    
    func test_valid_tokenization_responses() throws {
        var tokenizationResponseDictionary = _tokenizationResponseDictionary
        var tokenizationResponseData = try JSONSerialization.data(withJSONObject: tokenizationResponseDictionary)
        var primerPaymentMethodToken = try JSONDecoder().decode(PrimerPaymentMethodTokenData.self, from: tokenizationResponseData)
        self.validatePaymentMethodTokenData(forResponse: tokenizationResponseDictionary, withToken: primerPaymentMethodToken)
        
        tokenizationResponseDictionary["analyticsId"] = nil
        tokenizationResponseDictionary["isAlreadyVaulted"] = true
        tokenizationResponseDictionary["isVaulted"] = true
        var paymentInstrumentData = tokenizationResponseDictionary["paymentInstrumentData"] as? [String: Any]
        paymentInstrumentData?["first6Digits"] = nil
        paymentInstrumentData?["last4Digits"] = nil
        paymentInstrumentData?["paymentMethodConfigId"] = nil
        paymentInstrumentData?["paypalBillingAgreementId"] = nil
        tokenizationResponseDictionary["paymentInstrumentData"] = paymentInstrumentData
        
        tokenizationResponseData = try JSONSerialization.data(withJSONObject: tokenizationResponseDictionary)
        primerPaymentMethodToken = try JSONDecoder().decode(PrimerPaymentMethodTokenData.self, from: tokenizationResponseData)
        self.validatePaymentMethodTokenData(forResponse: tokenizationResponseDictionary, withToken: primerPaymentMethodToken)
    }
    
    func test_tokenization_response_with_missing_payment_method_type() throws {
        var tokenizationResponseDictionary = _tokenizationResponseDictionary
        var paymentInstrumentData = tokenizationResponseDictionary["paymentInstrumentData"] as? [String: Any]
        paymentInstrumentData?["paymentMethodType"] = nil
        tokenizationResponseDictionary["paymentInstrumentData"] = paymentInstrumentData
        var tokenizationResponseData = try JSONSerialization.data(withJSONObject: tokenizationResponseDictionary)
        
        do {
            let primerPaymentMethodToken = try JSONDecoder().decode(PrimerPaymentMethodTokenData.self, from: tokenizationResponseData)
            XCTAssert(true, "Decoder should fail to decode tokenization response")
        } catch {
            if case Swift.DecodingError.keyNotFound = error {
                
            } else {
                XCTAssert(true, error.localizedDescription)
            }
        }
        
    }
    
    // MARK: Helpers
    
    func validatePaymentMethodTokenData(forResponse tokenizationResponse: [String: Any], withToken primerPaymentMethodToken: PrimerPaymentMethodTokenData) {
        XCTAssert(primerPaymentMethodToken.analyticsId == tokenizationResponse["analyticsId"] as? String, "analyticsId is \(primerPaymentMethodToken.analyticsId ?? "n/a") when it should be \(tokenizationResponse["analyticsId"] as? String ?? "n/a")")
        XCTAssert(primerPaymentMethodToken.isAlreadyVaulted == tokenizationResponse["isAlreadyVaulted"] as? Bool, "isAlreadyVaulted is \(primerPaymentMethodToken.isAlreadyVaulted) when it should be \(tokenizationResponse["isAlreadyVaulted"] as? Bool)")
        XCTAssert(primerPaymentMethodToken.isVaulted == tokenizationResponse["isVaulted"] as? Bool, "isVaulted is \(primerPaymentMethodToken.isVaulted) when it should be \(tokenizationResponse["isVaulted"] as? Bool)")
        XCTAssert(primerPaymentMethodToken.paymentInstrumentData != nil, "paymentInstrumentData should not be nil")
        
        let paymentInstrumentDataResponse = tokenizationResponse["paymentInstrumentData"] as? [String: Any]
        XCTAssert(primerPaymentMethodToken.paymentInstrumentData?.first6Digits == paymentInstrumentDataResponse?["first6Digits"] as? String, "paymentInstrumentData.first6Digits is \(primerPaymentMethodToken.paymentInstrumentData?.first6Digits ?? "n/a") when it should be \(paymentInstrumentDataResponse?["first6Digits"] as? String ?? "n/a")")
        XCTAssert(primerPaymentMethodToken.paymentInstrumentData?.last4Digits == paymentInstrumentDataResponse?["last4Digits"] as? String, "paymentInstrumentData.last4Digits is \(primerPaymentMethodToken.paymentInstrumentData?.last4Digits ?? "n/a") when it should be \(paymentInstrumentDataResponse?["last4Digits"] as? String ?? "n/a")")
        
        XCTAssert(primerPaymentMethodToken.paymentInstrumentData?.paymentMethodConfigId == paymentInstrumentDataResponse?["paymentMethodConfigId"] as? String, "paymentInstrumentData.paymentMethodConfigId is \(primerPaymentMethodToken.paymentInstrumentData?.paymentMethodConfigId ?? "n/a") when it should be \(paymentInstrumentDataResponse?["paymentMethodConfigId"] as? String ?? "n/a")")
        XCTAssert(primerPaymentMethodToken.paymentInstrumentData?.paymentMethodType == paymentInstrumentDataResponse?["paymentMethodType"] as? String, "paymentInstrumentData.paymentMethodType is \(primerPaymentMethodToken.paymentInstrumentData?.paymentMethodType ?? "n/a") when it should be \(paymentInstrumentDataResponse?["paymentMethodType"] as? String ?? "n/a")")
        XCTAssert(primerPaymentMethodToken.paymentInstrumentData?.paypalBillingAgreementId == paymentInstrumentDataResponse?["paypalBillingAgreementId"] as? String, "paymentInstrumentData.paypalBillingAgreementId is \(primerPaymentMethodToken.paymentInstrumentData?.paypalBillingAgreementId ?? "n/a") when it should be \(paymentInstrumentDataResponse?["paypalBillingAgreementId"] as? String ?? "n/a")")
        XCTAssert(primerPaymentMethodToken.paymentInstrumentData?.sessionInfo != nil, "primerPaymentMethodToken.paymentInstrumentData?.sessionInfo should not be nil")
        
        let sessionInfo = paymentInstrumentDataResponse?["sessionInfo"] as? [String: Any]
        XCTAssert(primerPaymentMethodToken.paymentInstrumentData?.sessionInfo?.locale == sessionInfo?["locale"] as? String, "paymentInstrumentData?.sessionInfo?.locale is \(primerPaymentMethodToken.paymentInstrumentData?.sessionInfo?.locale ?? "n/a") when it should be \(sessionInfo?["locale"] as? String ?? "n/a")")
        XCTAssert(primerPaymentMethodToken.paymentInstrumentData?.sessionInfo?.platform == sessionInfo?["platform"] as? String, "paymentInstrumentData?.sessionInfo?.platform is \(primerPaymentMethodToken.paymentInstrumentData?.sessionInfo?.platform ?? "n/a") when it should be \(sessionInfo?["platform"] as? String ?? "n/a")")
        XCTAssert(primerPaymentMethodToken.paymentInstrumentData?.sessionInfo?.redirectionUrl == sessionInfo?["redirectionUrl"] as? String, "paymentInstrumentData?.sessionInfo?.redirectionUrl is \(primerPaymentMethodToken.paymentInstrumentData?.sessionInfo?.redirectionUrl ?? "n/a") when it should be \(sessionInfo?["redirectionUrl"] as? String ?? "n/a")")
        
        XCTAssert(primerPaymentMethodToken.paymentInstrumentType.rawValue == tokenizationResponse["paymentInstrumentType"] as? String, "paymentInstrumentType is \(primerPaymentMethodToken.paymentInstrumentType) when it should be \(tokenizationResponse["paymentInstrumentType"] as? String ?? "n/a")")
        XCTAssert(primerPaymentMethodToken.threeDSecureAuthentication != nil, "primerPaymentMethodToken.threeDSecureAuthentication should not be nil")
        
        let threeDSecureAuthentication = tokenizationResponse["threeDSecureAuthentication"] as? [String: Any]
        XCTAssert(primerPaymentMethodToken.threeDSecureAuthentication?.responseCode.rawValue == threeDSecureAuthentication?["responseCode"] as? String, "threeDSecureAuthentication?.responseCode is \(primerPaymentMethodToken.threeDSecureAuthentication?.responseCode) when it should be \(threeDSecureAuthentication?["responseCode"] as? String ?? "n/a")")
        XCTAssert(primerPaymentMethodToken.threeDSecureAuthentication?.reasonCode == threeDSecureAuthentication?["reasonCode"] as? String, "threeDSecureAuthentication?.reasonCode is \(primerPaymentMethodToken.threeDSecureAuthentication?.reasonCode) when it should be \(threeDSecureAuthentication?["reasonCode"] as? String ?? "n/a")")
        XCTAssert(primerPaymentMethodToken.threeDSecureAuthentication?.reasonText == threeDSecureAuthentication?["reasonText"] as? String, "threeDSecureAuthentication?.reasonText is \(primerPaymentMethodToken.threeDSecureAuthentication?.reasonText) when it should be \(threeDSecureAuthentication?["reasonText"] as? String ?? "n/a")")
        XCTAssert(primerPaymentMethodToken.threeDSecureAuthentication?.reasonText == threeDSecureAuthentication?["reasonText"] as? String, "threeDSecureAuthentication?.protocolVersion is \(primerPaymentMethodToken.threeDSecureAuthentication?.protocolVersion) when it should be \(threeDSecureAuthentication?["protocolVersion"] as? String ?? "n/a")")
    }
}
