//
//  PrimerPhoneNumberData.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public final class PrimerPhoneNumberData: PrimerRawData {

    public var phoneNumber: String {
        didSet {
            self.onDataDidChange?()
        }
    }

    private enum CodingKeys: String, CodingKey {
        case phoneNumber
    }

    public required init(
        phoneNumber: String
    ) {
        self.phoneNumber = phoneNumber
        super.init()
    }
}
