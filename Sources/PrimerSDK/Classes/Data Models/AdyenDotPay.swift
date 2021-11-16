//
//  AdyenDotPay.swift
//  PrimerSDK
//
//  Created by Admin on 8/11/21.
//

#if canImport(UIKit)

import Foundation

internal struct BankTokenizationSessionRequest: Encodable {
    let paymentMethodConfigId: String
    let command: String = "FETCH_BANK_ISSUERS"
    let parameters: BankTokenizationSessionRequestParameters
}

internal struct BankTokenizationSessionRequestParameters: Encodable {
    let paymentMethod: String
}

internal struct BanksListSessionResponse: Decodable {
    let result: [Bank]
}

#endif
