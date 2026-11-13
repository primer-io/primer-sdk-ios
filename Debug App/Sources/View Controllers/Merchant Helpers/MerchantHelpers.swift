//
//  MerchantHelpers.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import UIKit

struct MerchantMockDataManager {

    enum SessionType {
        case generic
        case klarnaWithEMD
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
        ClientSessionRequestBody(
            customerId: customerId,
            orderId: "ios-order-\(String.randomString(length: 8))",
            currencyCode: CurrencyLoader().getCurrency("EUR")?.code,
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
            paymentMethod: getPaymentMethod(sessionType: sessionType),
            testParams: nil)
    }

    static func getPaymentMethod(sessionType: SessionType) -> ClientSessionRequestBody.PaymentMethod {
        sessionType == .generic ? genericPaymentMethod : klarnaPaymentMethod
    }

    static var genericPaymentMethod = ClientSessionRequestBody.PaymentMethod(
        vaultOnSuccess: false,
        options: ClientSessionRequestBody.PaymentMethod.PaymentMethodOptionGroup(),
        descriptor: "Random descriptor",
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
            captureVaultedCardCvv: false,
            merchantName: nil,
            networks: nil))

    static var extraMerchantData: ExtraMerchantData = ExtraMerchantData(
        subscription: [
            ExtraMerchantData.Subscription(
                subscriptionName: "Implant_lenses",
                startTime: "2020-11-24T15:00",
                endTime: "2021-11-24T15:00",
                autoRenewalOfSubscription: false)
        ],
        customerAccountInfo: [
            ExtraMerchantData.CustomerAccountInfo(
                uniqueAccountIdentifier: "Owen Owenson",
                accountRegistrationDate: "2020-11-24T15:00",
                accountLastModified: "2020-11-24T15:00")
        ])
}
