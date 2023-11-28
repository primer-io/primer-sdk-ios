//
//  PaymentResponse.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/9/21.
//

import Foundation

@objc
internal enum PaymentStatus: Int, Codable {
    case pending = 0
    case failed
    case authorized
    case settling
    case partiallySettled
    case settled
    case declined
    case cancelled

    public init?(strValue: String) {
        switch strValue.uppercased() {
        case "PENDING":
            self = .pending
        case "FAILED":
            self = .failed
        case "AUTHORIZED":
            self = .authorized
        case "SETTLING":
            self = .settling
        case "PARTIALLY_SETTLED":
            self = .partiallySettled
        case "SETTLED":
            self = .settled
        case "DECLINED":
            self = .declined
        case "CANCELLED":
            self = .cancelled
        default:
            return nil
        }
    }
}

public enum RequiredActionName: String, Codable {
    case checkout = "CHECKOUT"
    case threeDSAuthentication = "3DS_AUTHENTICATION"
    case usePrimerSDK = "USE_PRIMER_SDK"
    case processor3DS = "PROCESSOR_3DS"
    case paymentMethodVoucher = "PAYMENT_METHOD_VOUCHER"
}

internal protocol PaymentResponseProtocol {
    var id: String { get }
    var date: String { get }
    var status: PaymentStatus { get }
    var requiredAction: RequiredActionProtocol? { get }
}

internal protocol RequiredActionProtocol {
    var name: RequiredActionName { get }
    var description: String { get }
    var clientToken: String? { get }
}
