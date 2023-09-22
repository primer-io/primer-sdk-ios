//
//  NolPayPaymentCard.swift
//  PrimerSDK
//
//  Created by Boris on 22.9.23..
//

import Foundation
#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
#endif

public class PrimerNolPaymentCard {
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
