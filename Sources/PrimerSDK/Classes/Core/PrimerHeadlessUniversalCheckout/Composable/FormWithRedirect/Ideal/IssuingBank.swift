//
//  IssuingBank.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@objc public final class IssuingBank: NSObject, Encodable {
    public let id: String
    public let name: String
    public let iconUrl: String?
    public let isDisabled: Bool
    init(bank: AdyenBank) {
        self.id = bank.id
        self.name = bank.name
        self.iconUrl = bank.iconUrlStr
        self.isDisabled = bank.disabled
    }
}
