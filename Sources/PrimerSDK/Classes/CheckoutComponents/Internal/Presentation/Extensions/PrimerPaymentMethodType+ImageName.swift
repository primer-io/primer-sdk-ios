//
//  PrimerPaymentMethodType+ImageName.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// CheckoutComponents extension for mapping payment method types to bundled image assets
/// This keeps the data model (PrimerPaymentMethodType) clean and UI-agnostic
extension PrimerPaymentMethodType {

    /// Returns the default ImageName for this payment method type
    /// Used when server doesn't provide a payment method icon
    /// Follows the same pattern as DropIn UI's TokenizationResponse.icon
    var defaultImageName: ImageName {
        switch self {
        // PayPal variants
        case .payPal, .primerTestPayPal:
            return .paypal
            
        // Klarna variants
        case .klarna, .primerTestKlarna:
            return .klarna
            
        // Card payments
        case .paymentCard:
            return .creditCard
            
        // Apple Pay
        case .applePay:
            return .appleIcon
            
        // Bank/ACH payments
        case .goCardless, .stripeAch:
            return .achBank
            
        // Google Pay
        case .googlePay:
            return .appleIcon  // Uses same icon as Apple Pay
            
        // All other payment methods use generic card
        default:
            return .genericCard
        }
    }
}
