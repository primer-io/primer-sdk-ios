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
 
 - Author:
 Primer
 - Version:
 1.2.2
 */

public enum PrimerSessionFlow {

    case primerWithVault
    case primerCheckout
    case vaultCard
    case checkoutWithCard
    case vaultPayPal
    case checkoutWithPayPal
    case vaultDirectDebit
    case vaultKlarna
    case checkoutWithKlarna
    
    var vaulted: Bool {
        switch self {
        case .primerWithVault,
             .vaultCard,
             .vaultPayPal,
             .vaultDirectDebit,
             .vaultKlarna:
            return true
        case .checkoutWithCard,
             .checkoutWithPayPal,
             .checkoutWithKlarna,
             .primerCheckout:
            return false
        
        }
    }

    var uxMode: UXMode {
        switch self {
        case .vaultCard,
             .vaultPayPal,
             .vaultDirectDebit,
             .vaultKlarna,
             .primerWithVault:
            return .VAULT
        case .checkoutWithCard,
             .checkoutWithPayPal,
             .primerCheckout,
             .checkoutWithKlarna:
            return .CHECKOUT
        }
    }
}
