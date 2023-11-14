//
//  VaultedPaymentMethods.swift
//  PrimerSDK
//
//  Created by Evangelos on 5/9/22.
//

import Foundation

extension Response.Body {

    struct VaultedPaymentMethods: Codable {
        let data: [PrimerPaymentMethodTokenData]
    }
}
