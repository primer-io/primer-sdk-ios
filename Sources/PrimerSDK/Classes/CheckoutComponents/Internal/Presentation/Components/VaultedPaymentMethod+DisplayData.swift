//
//  VaultedPaymentMethod+DisplayData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

// MARK: - VaultedPaymentMethod Display Data Extension

@available(iOS 15.0, *)
extension PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {

    /// Extracts normalized display data based on payment instrument type.
    /// This computed property handles the polymorphic nature of vaulted payment methods,
    /// returning a unified display model regardless of the underlying payment type.
    var displayData: VaultedPaymentMethodDisplayData {
        switch paymentInstrumentType {
        case .paymentCard, .cardOffSession:
            cardDisplayData(from: paymentInstrumentData)
        case .payPalBillingAgreement:
            paypalDisplayData(from: paymentInstrumentData)
        case .klarna, .klarnaCustomerToken, .klarnaPaymentSession:
            klarnaDisplayData(from: paymentInstrumentData)
        case .stripeAch:
            achDisplayData(from: paymentInstrumentData)
        case .goCardlessMandate:
            goCardlessDisplayData(from: paymentInstrumentData)
        case .applePay:
            applePayDisplayData()
        case .googlePay:
            googlePayDisplayData()
        default:
            genericDisplayData()
        }
    }

    // MARK: - Card Display Data

    private func cardDisplayData(from data: Response.Body.Tokenization.PaymentInstrumentData) -> VaultedPaymentMethodDisplayData {
        let network = data.network ?? data.binData?.network ?? "Card"
        let cardNetwork = CardNetwork(rawValue: network.uppercased()) ?? .unknown
        let brandIcon = cardNetwork.icon ?? ImageName.creditCard.image

        let last4 = data.last4Digits
        let primaryValue = last4.map { CheckoutComponentsStrings.maskedCardNumberFormatted($0) }

        var secondaryValue: String?
        if let month = data.expirationMonth, let year = data.expirationYear {
            let shortYear = year.count > 2 ? String(year.suffix(2)) : year
            secondaryValue = CheckoutComponentsStrings.expiresDate("\(month)/\(shortYear)")
        }

        let accessibilityLabel = CheckoutComponentsStrings.a11yVaultedCard(
            network: cardNetwork.displayName,
            last4: last4 ?? "****",
            expiry: secondaryValue ?? "",
            name: data.cardholderName
        )

        return VaultedPaymentMethodDisplayData(
            name: data.cardholderName,
            brandIcon: brandIcon,
            brandName: cardNetwork.displayName,
            primaryValue: primaryValue,
            secondaryValue: secondaryValue,
            accessibilityLabel: accessibilityLabel
        )
    }

    // MARK: - PayPal Display Data

    private func paypalDisplayData(from data: Response.Body.Tokenization.PaymentInstrumentData) -> VaultedPaymentMethodDisplayData {
        let payerInfo = data.externalPayerInfo
        let name = buildPayPalName(from: payerInfo)
        let email = payerInfo?.email
        let maskedEmail = email.map { maskEmail($0) }

        let accessibilityLabel = CheckoutComponentsStrings.a11yVaultedPayPal(
            email: email,
            name: name
        )

        return VaultedPaymentMethodDisplayData(
            name: name,
            brandIcon: UIImage(primerResource: "paypal-icon-colored"),
            brandName: CheckoutComponentsStrings.paypalBrandName,
            primaryValue: maskedEmail,
            secondaryValue: nil,
            accessibilityLabel: accessibilityLabel
        )
    }

    private func buildPayPalName(from payerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo?) -> String? {
        guard let payerInfo else { return nil }

        let firstName = payerInfo.firstName ?? payerInfo.firstNameSnakeCase
        let lastName = payerInfo.lastName ?? payerInfo.lastNameSnakeCase

        if let firstName, let lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName {
            return firstName
        } else if let lastName {
            return lastName
        }
        return nil
    }

    // MARK: - Klarna Display Data

    private func klarnaDisplayData(from data: Response.Body.Tokenization.PaymentInstrumentData) -> VaultedPaymentMethodDisplayData {
        let email = data.sessionData?.billingAddress?.email
        let maskedEmail = email.map { maskEmail($0) }

        let accessibilityLabel = CheckoutComponentsStrings.a11yVaultedKlarna(email: email)

        return VaultedPaymentMethodDisplayData(
            name: nil,
            brandIcon: UIImage(primerResource: "klarna-icon-colored"),
            brandName: CheckoutComponentsStrings.klarnaBrandName,
            primaryValue: maskedEmail,
            secondaryValue: nil,
            accessibilityLabel: accessibilityLabel
        )
    }

    // MARK: - ACH Display Data

    private func achDisplayData(from data: Response.Body.Tokenization.PaymentInstrumentData) -> VaultedPaymentMethodDisplayData {
        let bankName = data.bankName ?? "Bank"
        let brandName = "\(bankName) \(CheckoutComponentsStrings.achSuffix)"

        let last4 = data.accountNumberLast4Digits
        let primaryValue = last4.map { CheckoutComponentsStrings.maskedCardNumberFormatted($0) }

        let accessibilityLabel = CheckoutComponentsStrings.a11yVaultedACH(
            bankName: bankName,
            last4: last4
        )

        return VaultedPaymentMethodDisplayData(
            name: data.cardholderName,
            brandIcon: ImageName.achBank.image,
            brandName: brandName,
            primaryValue: primaryValue,
            secondaryValue: nil,
            accessibilityLabel: accessibilityLabel
        )
    }

    // MARK: - GoCardless Display Data

    private func goCardlessDisplayData(from data: Response.Body.Tokenization.PaymentInstrumentData) -> VaultedPaymentMethodDisplayData {
        let bankName = data.bankName ?? "Bank"
        let brandName = "\(bankName) (Direct Debit)"

        let last4 = data.accountNumberLast4Digits
        let primaryValue = last4.map { CheckoutComponentsStrings.maskedCardNumberFormatted($0) }

        let accessibilityLabel = CheckoutComponentsStrings.a11yVaultedACH(
            bankName: bankName,
            last4: last4
        )

        return VaultedPaymentMethodDisplayData(
            name: data.cardholderName,
            brandIcon: UIImage(primerResource: "gocardless-logo-colored"),
            brandName: brandName,
            primaryValue: primaryValue,
            secondaryValue: nil,
            accessibilityLabel: accessibilityLabel
        )
    }

    // MARK: - Apple Pay Display Data

    private func applePayDisplayData() -> VaultedPaymentMethodDisplayData {
        VaultedPaymentMethodDisplayData(
            name: nil,
            brandIcon: UIImage(primerResource: "apple-pay-icon-colored"),
            brandName: "Apple Pay",
            primaryValue: nil,
            secondaryValue: nil,
            accessibilityLabel: CheckoutComponentsStrings.a11yVaultedPaymentMethod("Apple Pay")
        )
    }

    // MARK: - Google Pay Display Data

    private func googlePayDisplayData() -> VaultedPaymentMethodDisplayData {
        VaultedPaymentMethodDisplayData(
            name: nil,
            brandIcon: UIImage(primerResource: "google-pay-icon"),
            brandName: "Google Pay",
            primaryValue: nil,
            secondaryValue: nil,
            accessibilityLabel: CheckoutComponentsStrings.a11yVaultedPaymentMethod("Google Pay")
        )
    }

    // MARK: - Generic Display Data

    private func genericDisplayData() -> VaultedPaymentMethodDisplayData {
        let icon = PrimerPaymentMethodType(rawValue: paymentMethodType)?.icon ?? ImageName.genericCard.image

        return VaultedPaymentMethodDisplayData(
            name: nil,
            brandIcon: icon,
            brandName: paymentMethodType,
            primaryValue: nil,
            secondaryValue: nil,
            accessibilityLabel: CheckoutComponentsStrings.a11yVaultedPaymentMethod(paymentMethodType)
        )
    }

    // MARK: - Email Masking

    private func maskEmail(_ email: String) -> String {
        guard let atIndex = email.firstIndex(of: "@") else {
            return email
        }

        let localPart = String(email[..<atIndex])
        let domain = String(email[atIndex...])

        if localPart.count <= 2 {
            return "\(localPart)••••\(domain)"
        }

        let visiblePrefix = String(localPart.prefix(2))
        return "\(visiblePrefix)••••\(domain)"
    }
}
