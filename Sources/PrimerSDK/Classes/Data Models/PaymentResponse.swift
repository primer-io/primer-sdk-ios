//
//  PaymentResponse.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/9/21.
//

import Foundation

public enum PaymentStatus: String, Codable {
    case pending = "PENDING"
    case failed = "FAILED"
    case authorized = "AUTHORIZED"
    case settling = "SETTLING"
    case partiallySettled = "PARTIALLY_SETTLED"
    case settled = "SETTLED"
    case declined = "DECLINED"
    case cancelled = "CANCELLED"
}

public enum RequiredActionName: String, Codable {
    case threeDSAuthentication = "3DS_AUTHENTICATION"
    case usePrimerSDK = "USE_PRIMER_SDK"
}

public protocol PaymentResponseProtocol {
    var id: String { get }
    var date: String { get }
    var status: PaymentStatus { get }
    var requiredAction: RequiredActionProtocol? { get }
}

public protocol RequiredActionProtocol {
    var name: RequiredActionName { get }
    var description: String { get }
    var clientToken: String? { get }
}
