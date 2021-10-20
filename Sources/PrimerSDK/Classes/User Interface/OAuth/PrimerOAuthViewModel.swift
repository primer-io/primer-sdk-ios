//
//  PrimerOAuthViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 6/8/21.
//

#if canImport(UIKit)

import Foundation

enum OAuthHost {
    case paypal
    case klarna
    case applePay
    case apaya
}

protocol PrimerOAuthViewModel {
    var host: OAuthHost { get }
    var didPresentPaymentMethod: (() -> Void)? { get set }
    func tokenize() -> Promise <PaymentMethodToken>
}

#endif
