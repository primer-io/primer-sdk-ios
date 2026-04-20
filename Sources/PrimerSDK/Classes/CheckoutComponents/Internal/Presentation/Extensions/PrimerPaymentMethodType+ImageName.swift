//
//  PrimerPaymentMethodType+ImageName.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@available(iOS 15.0, *)
extension PrimerPaymentMethodType {

  /// Follows the same pattern as DropIn UI's TokenizationResponse.icon
  var defaultImageName: ImageName {
    switch self {
    case .payPal, .primerTestPayPal: .paypal
    case .klarna, .primerTestKlarna, .adyenKlarna: .klarna
    case .paymentCard: .creditCard
    case .applePay: .appleIcon
    case .goCardless, .stripeAch: .achBank
    case .googlePay: .genericCard // TODO: Add .googlePay case to ImageName enum
    default: .genericCard
    }
  }

  /// Returns the icon image for this payment method type.
  /// Provides comprehensive coverage for all payment methods with fallback to generic card.
  var icon: UIImage? {
    switch self {
    // Primary payment methods
    case .payPal, .primerTestPayPal:
      UIImage(primerResource: "paypal-icon-colored")
    case .klarna, .primerTestKlarna, .adyenKlarna:
      UIImage(primerResource: "klarna-icon-colored")
    case .goCardless:
      UIImage(primerResource: "gocardless-logo-colored")
    case .stripeAch:
      ImageName.achBank.image
    case .applePay:
      UIImage(primerResource: "apple-pay-icon-colored")
    case .googlePay:
      UIImage(primerResource: "google-pay-icon")
    case .paymentCard:
      ImageName.creditCard.image

    // Alternative payment methods
    case .hoolah:
      UIImage(primerResource: "hoolah-icon-colored")
    case .atome:
      UIImage(primerResource: "atome-icon-colored")
    case .coinbase:
      UIImage(primerResource: "coinbase-icon-colored")

    // Adyen payment methods
    case .adyenAlipay:
      UIImage(primerResource: "alipay-icon-colored")
    case .adyenBlik:
      UIImage(primerResource: "blik-icon-colored")
    case .adyenBancontactCard:
      UIImage(primerResource: "bancontact-card-logo-colored")
    case .adyenDotPay:
      UIImage(primerResource: "dotpay-icon-colored")
    case .adyenGiropay:
      UIImage(primerResource: "giropay-icon")
    case .adyenIDeal:
      UIImage(primerResource: "ideal-icon-colored")
    case .adyenInterac:
      UIImage(primerResource: "interac-icon-colored")
    case .adyenMobilePay:
      UIImage(primerResource: "mobile-pay-icon")
    case .adyenMBWay:
      UIImage(primerResource: "mb-way-icon")
    case .adyenMultibanco:
      UIImage(primerResource: "multibanco-logo-colored")
    case .adyenPayTrail:
      UIImage(primerResource: "paytrail-icon")
    case .adyenPayshop:
      UIImage(primerResource: "payshop-icon-colored")
    case .adyenSofort, .primerTestSofort:
      UIImage(primerResource: "sofort-icon-colored")
    case .adyenTrustly:
      UIImage(primerResource: "trustly-icon-colored")
    case .adyenTwint:
      UIImage(primerResource: "twint-icon-colored")
    case .adyenVipps:
      UIImage(primerResource: "vipps-icon-colored")

    // Buckaroo payment methods
    case .buckarooBancontact:
      UIImage(primerResource: "bancontact-card-logo-colored")
    case .buckarooEps:
      UIImage(primerResource: "eps-icon-colored")
    case .buckarooGiropay:
      UIImage(primerResource: "giropay-icon")
    case .buckarooIdeal:
      UIImage(primerResource: "ideal-icon-colored")
    case .buckarooSofort:
      UIImage(primerResource: "sofort-icon-colored")

    // Mollie payment methods
    case .mollieBankcontact:
      UIImage(primerResource: "bancontact-card-logo-colored")
    case .mollieGiftcard:
      ImageName.genericCard.image
    case .mollieIdeal:
      UIImage(primerResource: "ideal-icon-colored")
    case .nets:
      ImageName.genericCard.image

    // Pay.nl payment methods
    case .payNLBancontact:
      UIImage(primerResource: "bancontact-card-logo-colored")
    case .payNLGiropay:
      UIImage(primerResource: "giropay-icon")
    case .payNLIdeal:
      UIImage(primerResource: "ideal-icon-colored")
    case .payNLKaartdirect:
      ImageName.genericCard.image
    case .payNLPayconiq:
      UIImage(primerResource: "payconiq-icon-colored")

    // Rapyd payment methods
    case .rapydGCash:
      UIImage(primerResource: "gcash-icon")
    case .rapydGrabPay:
      UIImage(primerResource: "grab-pay-icon")
    case .rapydPromptPay, .omisePromptPay:
      UIImage(primerResource: "promptpay-logo-colored")

    // Other payment methods
    case .xfersPayNow:
      UIImage(primerResource: "paynow-icon-colored")
    case .fintechtureSmartTransfer, .fintechtureImmediateTransfer:
      UIImage(primerResource: "fintecture-icon")

    // Fallback
    default:
      ImageName.genericCard.image
    }
  }
}
