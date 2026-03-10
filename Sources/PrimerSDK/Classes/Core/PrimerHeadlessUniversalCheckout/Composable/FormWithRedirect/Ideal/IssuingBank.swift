//
//  IssuingBank.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerNetworking

@objc public final class IssuingBank: NSObject, Encodable {
    public let id: String
    public let name: String
    public let iconUrl: String?
    public let isDisabled: Bool
    init(bank: AdyenBank) {
        id = bank.id
        name = bank.name
        iconUrl = bank.iconUrlStr
        isDisabled = bank.disabled
    }
}
