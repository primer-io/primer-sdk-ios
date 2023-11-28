//
//  IssuingBank.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 21.11.2023.
//

import Foundation
@objc public final class IssuingBank: NSObject {
    public let id: String
    public let name: String
    public let iconUrlStr: String?
    public let isDisabled: Bool
    init(bank: AdyenBank) {
        self.id = bank.id
        self.name = bank.name
        self.iconUrlStr = bank.iconUrlStr
        self.isDisabled = bank.disabled
    }
}
