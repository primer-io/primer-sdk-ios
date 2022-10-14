//
//  Networking+Models.swift
//  PrimerSDK_Example
//
//  Created by Dario Carlomagno on 10/05/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import PrimerSDK

extension Networking {
    
    static func createClientSessionRequestBodyWithParameters(
        amount: Int?,
        currency: Currency?,
        customerId: String,
        phoneNumber: String?,
        countryCode: CountryCode?
    ) -> ClientSessionRequestBody {
        
        var metadataTestCaseDict: [String : Any]? = nil
        if let metadataTestCaseStringValue = metadataTestCase {
            metadataTestCaseDict = ["TEST_CASE": metadataTestCaseStringValue]
        }
        
        return ClientSessionRequestBody(
            customerId: customerId,
            orderId: "ios_order_id_\(String.randomString(length: 8))",
            currencyCode: currency,
            amount: nil,
            metadata: metadataTestCaseDict,
            customer: ClientSessionRequestBody.Customer(
                firstName: "John",
                lastName: "Smith",
                emailAddress: "john@primer.io",
                mobileNumber: "+4478888888888",
                billingAddress: Address(
                    firstName: "John",
                    lastName: "Smith",
                    addressLine1: "65 York Road",
                    addressLine2: nil,
                    city: "London",
                    state: nil,
                    countryCode: countryCode?.rawValue ?? "GB",
                    postalCode: "NW06 4OM"),
                shippingAddress: Address(
                    firstName: "John",
                    lastName: "Smith",
                    addressLine1: "9446 Richmond Road",
                    addressLine2: nil,
                    city: "London",
                    state: nil,
                    countryCode: countryCode?.rawValue ?? "GB",
                    postalCode: "EC53 8BT")
            ),
            order: ClientSessionRequestBody.Order(
                countryCode: countryCode,
                lineItems: [
                    ClientSessionRequestBody.Order.LineItem(
                        itemId: "shoes-382190",
                        description: "Fancy Shoes",
                        amount: amount,
                        quantity: 1),
                    //                    ClientSessionRequestBody.Order.LineItem(
                    //                        itemId: "hats-321441",
                    //                        description: "Cool Hat",
                    //                        amount: amount,
                    //                        quantity: 2)
                ]),
            paymentMethod: ClientSessionRequestBody.PaymentMethod(
                vaultOnSuccess: false,
                options:
                    [
                        "APPLE_PAY": [
                            "surcharge": [
                                "amount": 19
                            ]
                        ],
                        "PAY_NL_IDEAL": [
                            "surcharge": [
                                "amount": 39
                            ]
                        ],
                        "PAYPAL": [
                            "surcharge": [
                                "amount": 49
                            ]
                        ],
                        "ADYEN_TWINT": [
                            "surcharge": [
                                "amount": 59
                            ]
                        ],
                        "ADYEN_IDEAL": [
                            "surcharge": [
                                "amount": 69
                            ]
                        ],
                        "ADYEN_GIROPAY": [
                            "surcharge": [
                                "amount": 79
                            ]
                        ],
                        "BUCKAROO_BANCONTACT": [
                            "surcharge": [
                                "amount": 89
                            ]
                        ],
                        "PAYMENT_CARD": [
                            "networks": [
                                "VISA": [
                                    "surcharge": [
                                        "amount": 109
                                    ]
                                ],
                                "MASTERCARD": [
                                    "surcharge": [
                                        "amount": 129
                                    ]
                                ]
                            ]
                        ]
                    ]
            )
        )
    }
}
