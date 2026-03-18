//
//  PaymentMethodImplementationType.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public enum PaymentMethodImplementationType: String, Codable, CaseIterable, Equatable, Hashable {

    case nativeSdk      = "NATIVE_SDK"
    case webRedirect    = "WEB_REDIRECT"
    case iPay88Sdk      = "IPAY88_SDK"
    case formWithRedirect = "FORM_WITH_REDIRECT"

    public var isEnabled: Bool {
        true
    }
}
