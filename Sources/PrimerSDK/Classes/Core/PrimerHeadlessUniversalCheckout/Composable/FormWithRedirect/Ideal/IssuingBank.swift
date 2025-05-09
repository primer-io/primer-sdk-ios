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
        id = bank.id
        name = bank.name
        iconUrl = bank.iconUrlStr
        isDisabled = bank.disabled
    }
}
