//
//  PaymentResponse.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public enum RequiredActionName: String, Codable {
    case checkout = "CHECKOUT"
    case threeDSAuthentication = "3DS_AUTHENTICATION"
    case usePrimerSDK = "USE_PRIMER_SDK"
    case processor3DS = "PROCESSOR_3DS"
    case paymentMethodVoucher = "PAYMENT_METHOD_VOUCHER"
}
