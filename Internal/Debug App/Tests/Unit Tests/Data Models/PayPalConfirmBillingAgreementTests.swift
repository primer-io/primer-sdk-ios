//
//  PayPalConfirmBillingAgreementTests.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 30/5/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class PayPalConfirmBillingAgreementTests: XCTestCase {
    
    let _validPayPalConfirmBillingAgreementDictionary: [String: Any] = [
        "shippingAddress": [
            "city": "London",
            "firstName": "John",
            "postalCode": "E1 6RL",
            "addressLine1": "Spitalfields Arts Market",
            "countryCode": "GB",
            "addressLine2": nil,
            "state": "London",
            "lastName": "Doe"
        ],
        "externalPayerInfo": [
            "email": "test@email.com",
            "firstName": "John",
            "lastName": "Doe",
            "externalPayerId": "0000"
        ],
        "billingAgreementId": "billing-agreement"
    ]
    
    func test_valid_paypal_confirm_billing_agreement_responses() throws {
        var dict = _validPayPalConfirmBillingAgreementDictionary
        var data = try JSONSerialization.data(withJSONObject: dict)
        var confirmBillingAgreement = try JSONDecoder().decode(Response.Body.PayPal.ConfirmBillingAgreement.self, from: data)
        try validate(confirmBillingAgreement: confirmBillingAgreement, with: dict)
        
        dict = _validPayPalConfirmBillingAgreementDictionary
        dict["shippingAddress"] = [
            "city": nil,
            "firstName": nil,
            "postalCode": nil,
            "addressLine1": nil,
            "countryCode": nil,
            "addressLine2": nil,
            "state": nil,
            "lastName": nil,
        ] as [String : Any?]
        data = try JSONSerialization.data(withJSONObject: dict)
        confirmBillingAgreement = try JSONDecoder().decode(Response.Body.PayPal.ConfirmBillingAgreement.self, from: data)
        try validate(confirmBillingAgreement: confirmBillingAgreement, with: dict)
        
        dict = _validPayPalConfirmBillingAgreementDictionary
        dict["shippingAddress"] = nil
        data = try JSONSerialization.data(withJSONObject: dict)
        confirmBillingAgreement = try JSONDecoder().decode(Response.Body.PayPal.ConfirmBillingAgreement.self, from: data)
        try validate(confirmBillingAgreement: confirmBillingAgreement, with: dict)
    }
    
    func test_invalid_paypal_confirm_billing_agreement_responses() throws {
        var dict = _validPayPalConfirmBillingAgreementDictionary
        dict["externalPayerInfo"] = nil
        var data = try JSONSerialization.data(withJSONObject: dict)
        
        do {
            let _ = try JSONDecoder().decode(Response.Body.PayPal.ConfirmBillingAgreement.self, from: data)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
        
        dict["billingAgreementId"] = nil
        data = try JSONSerialization.data(withJSONObject: dict)
        
        do {
            let _ = try JSONDecoder().decode(Response.Body.PayPal.ConfirmBillingAgreement.self, from: data)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func validate(confirmBillingAgreement: Response.Body.PayPal.ConfirmBillingAgreement, with response: [String: Any]) throws {
        XCTAssert((response["shippingAddress"] as? [String: Any])?["firstName"] as? String == confirmBillingAgreement.shippingAddress?.firstName)
        XCTAssert((response["shippingAddress"] as? [String: Any])?["lastName"] as? String == confirmBillingAgreement.shippingAddress?.lastName)
        XCTAssert((response["shippingAddress"] as? [String: Any])?["addressLine1"] as? String == confirmBillingAgreement.shippingAddress?.addressLine1)
        XCTAssert((response["shippingAddress"] as? [String: Any])?["addressLine2"] as? String == confirmBillingAgreement.shippingAddress?.addressLine2)
        XCTAssert((response["shippingAddress"] as? [String: Any])?["city"] as? String == confirmBillingAgreement.shippingAddress?.city)
        XCTAssert((response["shippingAddress"] as? [String: Any])?["state"] as? String == confirmBillingAgreement.shippingAddress?.state)
        XCTAssert((response["shippingAddress"] as? [String: Any])?["postalCode"] as? String == confirmBillingAgreement.shippingAddress?.postalCode)
        XCTAssert((response["shippingAddress"] as? [String: Any])?["countryCode"] as? String == confirmBillingAgreement.shippingAddress?.countryCode)
        
        XCTAssert((response["externalPayerInfo"] as? [String: Any])?["email"] as? String == confirmBillingAgreement.externalPayerInfo.email)
        XCTAssert((response["externalPayerInfo"] as? [String: Any])?["firstName"] as? String == confirmBillingAgreement.externalPayerInfo.firstName)
        XCTAssert((response["externalPayerInfo"] as? [String: Any])?["lastName"] as? String == confirmBillingAgreement.externalPayerInfo.lastName)
        XCTAssert((response["externalPayerInfo"] as? [String: Any])?["externalPayerId"] as? String == confirmBillingAgreement.externalPayerInfo.externalPayerId)
        
        XCTAssert(response["billingAgreementId"] as? String == confirmBillingAgreement.billingAgreementId)
    }
}

#endif

//{
//  "shippingAddress": {
//    "city": "London",
//    "firstName": "John",
//    "postalCode": "E1 6RL",
//    "addressLine1": "Spitalfields Arts Market",
//    "countryCode": "GB",
//    "addressLine2": null,
//    "state": "London",
//    "lastName": "Doe"
//  },
//  "externalPayerInfo": {
//    "email": "sb-358o431493298@personal.example.com",
//    "firstName": "John",
//    "lastName": "Doe",
//    "externalPayerId": "G9AXVJZPMD8WJ"
//  },
//  "billingAgreementId": "B-7YT1338453747735W"
//}
