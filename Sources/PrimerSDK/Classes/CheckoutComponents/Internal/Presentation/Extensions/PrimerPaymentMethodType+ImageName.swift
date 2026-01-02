//
//  PrimerPaymentMethodType+ImageName.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

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

    /// Returns the icon image for this payment method type.
    /// Provides comprehensive coverage for all payment methods with fallback to generic card.
    var icon: UIImage? {
        switch self {
        // Primary payment methods
        case .payPal, .primerTestPayPal:
            return UIImage(primerResource: "paypal-icon-colored")
        case .klarna, .primerTestKlarna:
            return UIImage(primerResource: "klarna-icon-colored")
        case .goCardless:
            return UIImage(primerResource: "gocardless-logo-colored")
        case .stripeAch:
            return ImageName.achBank.image
        case .applePay:
            return UIImage(primerResource: "apple-pay-icon-colored")
        case .googlePay:
            return UIImage(primerResource: "google-pay-icon")
        case .paymentCard:
            return ImageName.creditCard.image

        // Alternative payment methods
        case .hoolah:
            return UIImage(primerResource: "hoolah-icon-colored")
        case .atome:
            return UIImage(primerResource: "atome-icon-colored")
        case .coinbase:
            return UIImage(primerResource: "coinbase-icon-colored")

        // Adyen payment methods
        case .adyenAlipay:
            return UIImage(primerResource: "alipay-icon-colored")
        case .adyenBlik:
            return UIImage(primerResource: "blik-icon-colored")
        case .adyenBancontactCard:
            return UIImage(primerResource: "bancontact-card-logo-colored")
        case .adyenDotPay:
            return UIImage(primerResource: "dotpay-icon-colored")
        case .adyenGiropay:
            return UIImage(primerResource: "giropay-icon")
        case .adyenIDeal:
            return UIImage(primerResource: "ideal-icon-colored")
        case .adyenInterac:
            return UIImage(primerResource: "interac-icon-colored")
        case .adyenMobilePay:
            return UIImage(primerResource: "mobile-pay-icon")
        case .adyenMBWay:
            return UIImage(primerResource: "mb-way-icon")
        case .adyenMultibanco:
            return UIImage(primerResource: "multibanco-logo-colored")
        case .adyenPayTrail:
            return UIImage(primerResource: "paytrail-icon")
        case .adyenPayshop:
            return UIImage(primerResource: "payshop-icon-colored")
        case .adyenSofort, .primerTestSofort:
            return UIImage(primerResource: "sofort-icon-colored")
        case .adyenTrustly:
            return UIImage(primerResource: "trustly-icon-colored")
        case .adyenTwint:
            return UIImage(primerResource: "twint-icon-colored")
        case .adyenVipps:
            return UIImage(primerResource: "vipps-icon-colored")

        // Buckaroo payment methods
        case .buckarooBancontact:
            return UIImage(primerResource: "bancontact-card-logo-colored")
        case .buckarooEps:
            return UIImage(primerResource: "eps-icon-colored")
        case .buckarooGiropay:
            return UIImage(primerResource: "giropay-icon")
        case .buckarooIdeal:
            return UIImage(primerResource: "ideal-icon-colored")
        case .buckarooSofort:
            return UIImage(primerResource: "sofort-icon-colored")

        // Mollie payment methods
        case .mollieBankcontact:
            return UIImage(primerResource: "bancontact-card-logo-colored")
        case .mollieIdeal:
            return UIImage(primerResource: "ideal-icon-colored")

        // Pay.nl payment methods
        case .payNLBancontact:
            return UIImage(primerResource: "bancontact-card-logo-colored")
        case .payNLGiropay:
            return UIImage(primerResource: "giropay-icon")
        case .payNLIdeal:
            return UIImage(primerResource: "ideal-icon-colored")
        case .payNLPayconiq:
            return UIImage(primerResource: "payconiq-icon-colored")

        // Rapyd payment methods
        case .rapydGCash:
            return UIImage(primerResource: "gcash-icon")
        case .rapydGrabPay:
            return UIImage(primerResource: "grab-pay-icon")
        case .rapydPromptPay, .omisePromptPay:
            return UIImage(primerResource: "promptpay-logo-colored")

        // Other payment methods
        case .xfersPayNow:
            return UIImage(primerResource: "paynow-icon-colored")
        case .fintechtureSmartTransfer, .fintechtureImmediateTransfer:
            return UIImage(primerResource: "fintecture-icon")

        // Fallback
        default:
            return ImageName.genericCard.image
        }
    }
}
