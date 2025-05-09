//
//  PrimerPhoneNumberData.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 27/09/22.
//

import Foundation

public final class PrimerPhoneNumberData: PrimerRawData {

    public var phoneNumber: String {
        didSet {
            onDataDidChange?()
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
