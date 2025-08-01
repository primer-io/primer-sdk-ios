//
//  CardButtonViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol CardButtonViewModelProtocol {
    var network: String { get }
    var cardholder: String { get }
    var last4: String { get }
    var expiry: String { get }
    var imageName: ImageName { get }
    var paymentMethodType: PaymentInstrumentType { get }
    var surCharge: Int? { get }
}

struct CardButtonViewModel: CardButtonViewModelProtocol {

    let network, cardholder, last4, expiry: String
    let imageName: ImageName
    let paymentMethodType: PaymentInstrumentType
    var surCharge: Int? {
        let session = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
        guard let options = session?.paymentMethod?.options else { return nil }
        guard let paymentCardOption = options
                .filter({ $0["type"] as? String == PrimerPaymentMethodType.paymentCard.rawValue })
                .first else { return nil }
        guard let networks = paymentCardOption["networks"] as? [[String: Any]] else { return nil }
        guard let tmpNetwork = networks
                .filter({ ($0["type"] as? String)?.lowercased() == network.lowercased() })
                .first else { return nil }
        return tmpNetwork["surcharge"] as? Int
    }
}
