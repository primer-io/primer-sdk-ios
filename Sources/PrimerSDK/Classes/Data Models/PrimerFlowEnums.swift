//
//  SessionType.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

#if canImport(UIKit)

/**
 Enum that contains possible values for the drop-in UI flow.
 
 *Values*
 
 `default`: Cannot be added in vault and uses the checkout flow.
 
 `defaultWithVault`: Can be added in vault and uses the vault flow.
 
 `completeDirectCheckout`: Cannot be added in vault and uses the checkout flow.
 
 `addPayPalToVault`: Can be added in vault and uses the vault flow.
 
 `addCardToVault`: Can be added in vault and uses the vault flow.
 
 `addDirectDebitToVault`: Can be added in vault and uses the vault flow.
 
 `addKlarnaToVault`: Can be added in vault and uses the vault flow.
 
 `addDirectDebit`: Can be added in vault and uses the vault flow.
 
 `checkoutWithKlarna`: Can be added in vault and uses the checkout flow.
 
 `addApayaToVault`: Can be added in vault and uses the vault flow.
 
 - Author:
 Primer
 - Version:
 1.2.2
 */

public enum PrimerSessionFlow: Equatable {
    case `default`
    case defaultWithVault
    case completeDirectCheckout
    case addPayPalToVault
    case addCardToVault
    case addDirectDebitToVault
    case addKlarnaToVault
    case addDirectDebit
    case checkoutWithKlarna
    case checkoutWithPayPal
    case checkoutWithApplePay
    case addApayaToVault
    case checkoutWithAdyenBank
    case checkoutWithAsyncPaymentMethod(paymentMethodType: PrimerPaymentMethodType)

    internal var internalSessionFlow: PrimerInternalSessionFlow {
        switch self {
        case .`default`:
            return .checkout
        case .defaultWithVault:
            return .vault
        case .completeDirectCheckout:
            return .checkoutWithCard
        case .addPayPalToVault:
            return .vaultPayPal
        case .addCardToVault:
            return .vaultCard
        case .addDirectDebitToVault:
            return .vaultDirectDebit
        case .addKlarnaToVault:
            return .vaultKlarna
        case .addDirectDebit:
            return .vaultDirectDebit
        case .checkoutWithKlarna:
            return .checkoutWithKlarna
        case .checkoutWithApplePay:
            return .checkoutWithApplePay
        case .addApayaToVault:
            return .vaultApaya
        case .checkoutWithPayPal:
            return .checkoutWithPayPal
        case .checkoutWithAdyenBank:
            return .checkoutWithAdyenBank
        case .checkoutWithAsyncPaymentMethod(let type):
            return .checkoutWithExternalPaymentMethod(type: type)
        }
    }
}

internal enum PrimerInternalSessionFlow {

    case vault
    case checkout
    case vaultApaya
    case vaultCard
    case vaultDirectDebit
    case vaultPayPal
    case vaultKlarna
    case checkoutWithApplePay
    case checkoutWithCard
    case checkoutWithExternalPaymentMethod(type: PrimerPaymentMethodType)
    case checkoutWithKlarna
    case checkoutWithPayPal
    case checkoutWithAdyenBank
    
    var vaulted: Bool {
        switch self {
        case .vault,
             .vaultCard,
             .vaultPayPal,
             .vaultDirectDebit,
             .vaultKlarna,
             .vaultApaya:
            return true
        case .checkout,
             .checkoutWithCard,
             .checkoutWithExternalPaymentMethod,
             .checkoutWithPayPal,
             .checkoutWithKlarna,
             .checkoutWithApplePay,
             .checkoutWithAdyenBank:
            return false
        }
    }

    var uxMode: UXMode {
        switch self {
        case .vault,
             .vaultCard,
             .vaultPayPal,
             .vaultDirectDebit,
             .vaultKlarna,
             .vaultApaya:
            return .VAULT
        case .checkout,
             .checkoutWithCard,
             .checkoutWithExternalPaymentMethod,
             .checkoutWithPayPal,
             .checkoutWithKlarna,
             .checkoutWithApplePay,
             .checkoutWithAdyenBank:
            return .CHECKOUT
        }
    }
    
    var rawValue: String {
        switch self {
        case .vault:
            return "VAULT_MANAGER"
        case .checkout:
            return "UNIVERSAL_CHECKOUT"
        case .vaultApaya:
            return "VAULT_APAYA"
        case .vaultCard:
            return "VAULT_PAYMENT_CARD"
        case .vaultDirectDebit:
            return "VAULT_DIRECT_DEBIT"
        case .vaultPayPal:
            return "VAULT_PAYPAL"
        case .vaultKlarna:
            return "VAULT_KLARNA"
        case .checkoutWithApplePay:
            return "VAULT_APPLE_PAY"
        case .checkoutWithCard:
            return "CHECKOUT_PAYMENT_CARD"
        case .checkoutWithExternalPaymentMethod(type: let type):
            return "CHECKOUT_\(type.rawValue)"
        case .checkoutWithKlarna:
            return "CHECKOUT_KLARNA"
        case .checkoutWithPayPal:
            return "CHECKOUT_PAYPAL"
        case .checkoutWithAdyenBank:
            return "CHECKOUT_ADYEN_BANK"
        }
    }
}

public enum PrimerSessionIntent: String {
    case checkout
    case vault
}

#endif
