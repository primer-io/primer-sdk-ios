//
//  PrimerPhoneNumberData.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 27/09/22.
//

import Foundation

public class PrimerPhoneNumberData: PrimerRawData {

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
