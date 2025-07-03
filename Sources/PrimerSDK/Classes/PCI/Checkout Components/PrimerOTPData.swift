//
//  PrimerOTPData.swift
//  PrimerSDK
//
//  Created by Boris on 26.9.24..
//

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
