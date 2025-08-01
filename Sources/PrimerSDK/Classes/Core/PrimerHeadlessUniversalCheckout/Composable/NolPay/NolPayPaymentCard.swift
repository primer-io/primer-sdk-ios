//
//  NolPayPaymentCard.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
#endif

public final class PrimerNolPaymentCard {
    public var cardNumber: String
    public var expiredTime: String

    // Initializer that accepts a PrimerNolPayCard
    #if canImport(PrimerNolPaySDK)
    public init(from nolPayCard: PrimerNolPayCard) {
        self.cardNumber = nolPayCard.cardNumber
        self.expiredTime = nolPayCard.expiredTime
    }
    #endif
    // If you wish to also have an initializer that directly accepts card number and expiration time:
    public init(cardNumber: String, expiredTime: String) {
        self.cardNumber = cardNumber
        self.expiredTime = expiredTime
    }

    // Function to create PrimerNolPaymentCard array from PrimerNolPayCard array
    #if canImport(PrimerNolPaySDK)
    static func makeFrom(arrayOf primerNolPayCards: [PrimerNolPayCard]) -> [PrimerNolPaymentCard] {
        return primerNolPayCards.map { PrimerNolPaymentCard(cardNumber: $0.cardNumber, expiredTime: $0.expiredTime) }
    }
    #endif
}
