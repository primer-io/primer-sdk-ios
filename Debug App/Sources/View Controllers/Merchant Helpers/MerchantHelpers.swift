//
//  MerchantHelpers.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 01.02.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit
import PrimerSDK

struct MerchantMockDataManager {

    enum SessionType {
        case generic
        case oneTimePayment
    }

    static let customerIdStorageKey = "io.primer.debug.customer-id"

    static var customerId: String {
        if let customerId = UserDefaults.standard.string(forKey: customerIdStorageKey) {
            return customerId
        }

        let customerId = "ios-customer-\(String.randomString(length: 8))"
        UserDefaults.standard.set(customerId, forKey: customerIdStorageKey)
        return customerId
    }

    static func getClientSession(sessionType: SessionType) -> ClientSessionRequestBody {
        return ClientSessionRequestBody(
            customerId: customerId,
            orderId: "ios-order-\(String.randomString(length: 8))",
            currencyCode: CurrencyLoader().getCurrency("EUR"),
            amount: nil,
            metadata: nil,
            customer: ClientSessionRequestBody.Customer(
                firstName: "John",
                lastName: "Smith",
                emailAddress: "john@primer.io",
                mobileNumber: sessionType == .generic ? "+4478888888888" : "+4901761428434",
                billingAddress: Address(
                    firstName: "John",
                    lastName: "Smith",
                    addressLine1: sessionType == .generic ? "65 York Road" : "Neue Schönhauser Str. 2",
                    addressLine2: nil,
                    city: sessionType == .generic ? "London" : "Berlin",
                    state: sessionType == .generic ? "Greater London" : "Berlin",
                    countryCode: sessionType == .generic ? "GB" : "DE",
                    postalCode: sessionType == .generic ? "NW06 4OM" : "10178"),
                shippingAddress: Address(
                    firstName: "John",
                    lastName: "Smith",
                    addressLine1: sessionType == .generic ? "9446 Richmond Road" : "Neue Schönhauser Str. 2",
                    addressLine2: nil,
                    city: sessionType == .generic ? "London" : "Berlin",
                    state: sessionType == .generic ? "Greater London" : "Berlin",
                    countryCode: sessionType == .generic ? "GB" : "DE",
                    postalCode: sessionType == .generic ? "EC53 8BT" : "10178")
            ),
            order: ClientSessionRequestBody.Order(
                countryCode: .de,
                lineItems: [
                    ClientSessionRequestBody.Order.LineItem(
                        itemId: "fancy-shoes-\(String.randomString(length: 4))",
                        description: "Fancy Shoes",
                        amount: 600,
                        quantity: 1,
                        discountAmount: nil,
                        taxAmount: nil)
                ]),
            paymentMethod: sessionType == .generic ? genericPaymentMethod : klarnaPaymentMethod,
            testParams: nil)
    }

    static func getPaymentMethod(sessionType: SessionType) -> ClientSessionRequestBody.PaymentMethod {
        return sessionType == .generic ? genericPaymentMethod : klarnaPaymentMethod
    }

    static var genericPaymentMethod = ClientSessionRequestBody.PaymentMethod(
        vaultOnSuccess: false,
        options: nil,
        descriptor: nil,
        paymentType: nil
    )

    static var klarnaPaymentMethod = ClientSessionRequestBody.PaymentMethod(
        vaultOnSuccess: nil,
        options: klarnaPaymentOptions,
        descriptor: "test-descriptor",
        paymentType: nil
    )
    
    static var klarnaPaymentOptions = ClientSessionRequestBody.PaymentMethod.PaymentMethodOptionGroup(
        KLARNA: ClientSessionRequestBody.PaymentMethod.PaymentMethodOption(
            surcharge: ClientSessionRequestBody.PaymentMethod.SurchargeOption(amount: 140),
            instalmentDuration: "test",
            extraMerchantData: extraMerchantData, 
            captureVaultedCardCvv: false))

    static var extraMerchantData: [String: Any] = [
        "subscription": [
            [
                "subscription_name": "Implant_lenses",
                "start_time": "2020-11-24T15:00",
                "end_time": "2021-11-24T15:00",
                "auto_renewal_of_subscription": false
            ]
        ],
        "customer_account_info": [
            [
                "unique_account_identifier": "Owen Owenson",
                "account_registration_date": "2020-11-24T15:00",
                "account_last_modified": "2020-11-24T15:00"
            ]
        ]
    ]
}
