//
//  PrimerPaymentMethodType+ImageName.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// CheckoutComponents extension for mapping payment method types to bundled image assets
/// This keeps the data model (PrimerPaymentMethodType) clean and UI-agnostic
@available(iOS 15.0, *)
extension PrimerPaymentMethodType {

    /// Returns the default ImageName for this payment method type
    /// Used when server doesn't provide a payment method icon
    /// Follows the same pattern as DropIn UI's TokenizationResponse.icon
    var defaultImageName: ImageName {
        switch self {
        case .payPal, .primerTestPayPal: .paypal
        case .klarna, .primerTestKlarna: .klarna
        case .paymentCard: .creditCard
        case .applePay: .appleIcon
        case .goCardless, .stripeAch: .achBank
        case .googlePay: .appleIcon  // Uses same icon as Apple Pay
        default: .genericCard
        }
    }
}
