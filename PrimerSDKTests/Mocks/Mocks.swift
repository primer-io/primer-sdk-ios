//
//  PrimerSettings.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

@testable import PrimerSDK

var mockClientToken = ClientToken(
    accessToken: "bla",
    configurationUrl: "bla",
    paymentFlow: "bla",
    threeDSecureInitUrl: "bla",
    threeDSecureToken: "bla",
    coreUrl: "bla",
    pciUrl: "bla",
    env: "bla"
)

var mockSettings = PrimerSettings(
    amount: 200,
    currency: .EUR,
    clientTokenRequestCallback: { completion in },
    onTokenizeSuccess: { (result, callback) in },
    theme: PrimerTheme(),
    uxMode: .CHECKOUT,
    applePayEnabled: false,
    customerId: "cid",
    merchantIdentifier: "mid",
    countryCode: .FR
)
