//
//  IssuingBank.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 21.11.2023.
//

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
