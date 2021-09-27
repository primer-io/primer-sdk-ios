//
//  ApplePayViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockApplePayViewModel: ApplePayViewModelProtocol {

    var tokenizeCalled = false
    let paymentMethodTokenJSON: String = """
        """

    var host: OAuthHost = .applePay
    var didPresentPaymentMethod: (() -> Void)?
    
    var amount: Int?
    var orderItems: [OrderItem] { return [] }
    var clientToken: DecodedClientToken?
    var isVaulted: Bool = false
    var uxMode: UXMode = .CHECKOUT
    var applePayConfigId: String? = "applePayConfigId"
    var currency: Currency? = .EUR
    var merchantIdentifier: String? = "mid"
    var countryCode: CountryCode? = .fr
    
    func tokenize() -> Promise<PaymentMethodToken> {
        tokenizeCalled = true
        return Promise { seal in
            let paymentMethodTokenData = paymentMethodTokenJSON.data(using: .utf8)!
            let token = try! JSONParser().parse(PaymentMethodToken.self, from: paymentMethodTokenData)
            seal.fulfill(token)
        }
    }

}

#endif
