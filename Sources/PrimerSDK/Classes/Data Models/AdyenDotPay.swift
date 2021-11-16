//
//  AdyenDotPay.swift
//  PrimerSDK
//
//  Created by Admin on 8/11/21.
//

#if canImport(UIKit)

import Foundation

internal struct AdyenDotPaySessionRequest: Encodable {
    let paymentMethodConfigId: String
    let command: String = "FETCH_BANK_ISSUERS"
    let parameters: AdyenDotPaySessionRequestParameters
}

internal struct AdyenDotPaySessionRequestParameters: Encodable {
    let paymentMethod: String = "dotpay"
}

internal struct AdyenDotPaySessionResponse: Decodable {
    let result: [Bank]
}

#endif
