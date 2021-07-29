//
//  SessionType.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

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

public enum PrimerSessionFlow {
    case `default`
    case defaultWithVault
    case completeDirectCheckout
    case addPayPalToVault
    case addCardToVault
    case addDirectDebitToVault
    case addKlarnaToVault
    case addDirectDebit
    case checkoutWithKlarna
    case checkoutWithApplePay
    case addApayaToVault

    internal var internalSessionFlow: PrimerInternalSessionFlow {
        switch self {
        case .default:
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
        }
    }
}

internal enum PrimerInternalSessionFlow {

    case vault
    case checkout
    case vaultCard
    case checkoutWithCard
    case vaultPayPal
    case checkoutWithPayPal
    case vaultDirectDebit
    case vaultKlarna
    case checkoutWithKlarna
    case checkoutWithApplePay
    case vaultApaya
    
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
             .checkoutWithPayPal,
             .checkoutWithKlarna,
             .checkoutWithApplePay:
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
             .checkoutWithPayPal,
             .checkoutWithKlarna,
             .checkoutWithApplePay:
            return .CHECKOUT
        }
    }
}
