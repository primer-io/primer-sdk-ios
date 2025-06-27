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

    enum SessionType: Equatable {
        case generic
        case klarnaWithEMD
        case cardOnly
        case cardAndApplePay
        case applePay
        case custom(ClientSessionRequestBody.PaymentMethod)
        
        static func == (lhs: SessionType, rhs: SessionType) -> Bool {
            switch (lhs, rhs) {
            case (.generic, .generic),
                 (.klarnaWithEMD, .klarnaWithEMD),
                 (.cardOnly, .cardOnly),
                 (.cardAndApplePay, .cardAndApplePay),
                 (.applePay, .applePay):
                return true
            case (.custom(let lhsPaymentMethod), .custom(let rhsPaymentMethod)):
                // For custom cases, we'll compare by descriptor for simplicity
                return lhsPaymentMethod.descriptor == rhsPaymentMethod.descriptor
            default:
                return false
            }
        }
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
        switch sessionType {
        case .generic:
            return genericPaymentMethod
        case .klarnaWithEMD:
            return klarnaPaymentMethod
        case .cardOnly:
            return cardOnlyPaymentMethod
        case .cardAndApplePay:
            return cardAndApplePayPaymentMethod
        case .applePay:
            return applePayOnlyPaymentMethod
        case .custom(let paymentMethod):
            return paymentMethod
        }
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
    
    // MARK: - New Payment Method Configurations for CheckoutComponents Examples
    
    static var cardOnlyPaymentMethod = ClientSessionRequestBody.PaymentMethod(
        vaultOnSuccess: false,
        options: ClientSessionRequestBody.PaymentMethod.PaymentMethodOptionGroup(
            PAYMENT_CARD: cardOption
        ),
        descriptor: "Card only session",
        paymentType: nil
    )
    
    static var cardAndApplePayPaymentMethod = ClientSessionRequestBody.PaymentMethod(
        vaultOnSuccess: false,
        options: ClientSessionRequestBody.PaymentMethod.PaymentMethodOptionGroup(
            PAYMENT_CARD: cardOption,
            APPLE_PAY: applePayOption
        ),
        descriptor: "Card and Apple Pay session",
        paymentType: nil
    )
    
    static var applePayOnlyPaymentMethod = ClientSessionRequestBody.PaymentMethod(
        vaultOnSuccess: false,
        options: ClientSessionRequestBody.PaymentMethod.PaymentMethodOptionGroup(
            APPLE_PAY: applePayOption
        ),
        descriptor: "Apple Pay only session",
        paymentType: nil
    )
    
    static var cardOption = ClientSessionRequestBody.PaymentMethod.PaymentMethodOption(
        surcharge: nil,
        instalmentDuration: nil,
        extraMerchantData: nil,
        captureVaultedCardCvv: false,
        merchantName: nil,
        networks: nil
    )
    
    static var applePayOption = ClientSessionRequestBody.PaymentMethod.PaymentMethodOption(
        surcharge: nil,
        instalmentDuration: nil,
        extraMerchantData: nil,
        captureVaultedCardCvv: false,
        merchantName: nil,
        networks: nil
    )
}
