//
//  TokenizationResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerNetworking
import PrimerUI

// Should be removed
extension Response.Body.Tokenization {

    public var icon: ImageName {
        switch self.paymentInstrumentType {
        case .paymentCard:
            guard let network = self.paymentInstrumentData?.network else { return .genericCard }
            switch network {
            case "Visa": return .visa
            case "Mastercard": return .masterCard
            default: return .genericCard
            }
        case .payPalOrder: return .paypal2
        case .payPalBillingAgreement: return .paypal2
        case .goCardlessMandate: return .bank
        case .klarnaCustomerToken: return .klarna
        case .stripeAch: return .achBank
        default: return .creditCard
        }
    }

    var cardButtonViewModel: CardButtonViewModel? {
        switch self.paymentInstrumentType {
        case .paymentCard:
            guard let ntwrk = self.paymentInstrumentData?.binData?.network else { return nil }
            guard let last4 = self.paymentInstrumentData?.last4Digits else { return nil }
            guard let expMonth = self.paymentInstrumentData?.expirationMonth else { return nil }
            guard let expYear = self.paymentInstrumentData?.expirationYear else { return nil }
            return CardButtonViewModel(
                network: ntwrk,
                cardholder: self.paymentInstrumentData?.cardholderName ?? "",
                last4: "•••• \(last4)",
                expiry: Strings.PrimerCardFormView.savedCardTitle + " \(expMonth) / \(expYear.suffix(2))",
                imageName: self.icon,
                paymentMethodType: self.paymentInstrumentType
            )
        case .payPalBillingAgreement:
            guard let cardholder = self.paymentInstrumentData?.externalPayerInfo?.email else { return nil }
            return CardButtonViewModel(
                network: "PayPal",
                cardholder: cardholder,
                last4: "",
                expiry: "",
                imageName: self.icon,
                paymentMethodType: self.paymentInstrumentType
            )
        case .goCardlessMandate:
            return CardButtonViewModel(
                network: "Bank account",
                cardholder: "",
                last4: "",
                expiry: "",
                imageName: self.icon,
                paymentMethodType: self.paymentInstrumentType
            )
        case .klarnaCustomerToken:
            return CardButtonViewModel(
                network: paymentInstrumentData?.sessionData?.billingAddress?.email ?? "Klarna Customer Token",
                cardholder: "",
                last4: "",
                expiry: "",
                imageName: self.icon,
                paymentMethodType: self.paymentInstrumentType
            )
        case .stripeAch:
            return CardButtonViewModel(
                network: self.paymentInstrumentData?.bankName ?? "Bank account",
                cardholder: "•••• \(self.paymentInstrumentData?.accountNumberLast4Digits ?? "")",
                last4: "",
                expiry: "",
                imageName: self.icon,
                paymentMethodType: self.paymentInstrumentType
            )
        default:
            return nil
        }
    }
}
