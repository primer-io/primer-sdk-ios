//
//  PaymentResponse.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/9/21.
//

import Foundation

public enum RequiredActionName: String, Codable {
    case checkout = "CHECKOUT"
    case threeDSAuthentication = "3DS_AUTHENTICATION"
    case usePrimerSDK = "USE_PRIMER_SDK"
    case processor3DS = "PROCESSOR_3DS"
    case paymentMethodVoucher = "PAYMENT_METHOD_VOUCHER"
}

internal protocol RequiredActionProtocol {
    var name: RequiredActionName { get }
    var description: String { get }
    var clientToken: String? { get }
}
