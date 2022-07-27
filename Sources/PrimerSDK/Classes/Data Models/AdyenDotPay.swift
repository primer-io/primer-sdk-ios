//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import Foundation

internal struct BankTokenizationSessionRequest: Encodable {
    let paymentMethodConfigId: String
    let command: String = "FETCH_BANK_ISSUERS"
    let parameters: BankTokenizationSessionRequestParameters
}

internal struct BankTokenizationSessionRequestParameters: Encodable {
    let paymentMethod: String
}

internal struct BanksListSessionResponse: Decodable {
    let result: [Bank]
}

#endif
