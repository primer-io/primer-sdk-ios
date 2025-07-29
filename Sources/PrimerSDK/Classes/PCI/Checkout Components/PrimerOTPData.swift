//
//  PrimerOTPData.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public final class PrimerOTPData: PrimerRawData {

    public var otp: String {
        didSet {
            self.onDataDidChange?()
        }
    }

    private enum CodingKeys: String, CodingKey {
        case otp
    }

    public required init(
        otp: String
    ) {
        self.otp = otp
        super.init()
    }
}
