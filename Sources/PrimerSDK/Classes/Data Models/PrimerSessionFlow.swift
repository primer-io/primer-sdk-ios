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
        case .primerWithVault:
            return true
        case .vaultCard:
            return true
        case .checkoutWithCard:
            return false
        case .vaultPayPal:
            return true
        case .checkoutWithPayPal:
            return false
        case .vaultDirectDebit:
            return true
        case .vaultKlarna:
            return true
        case .checkoutWithKlarna:
            return false
        case .primerCheckout:
            return false
        
        }
    }

    var uxMode: UXMode {
        switch self {
        case .vaultCard:
            return .VAULT
        case .checkoutWithCard:
            return .CHECKOUT
        case .vaultPayPal:
            return .VAULT
        case .checkoutWithPayPal:
            return .CHECKOUT
        case .vaultDirectDebit:
            return .VAULT
        case .primerCheckout:
            return .CHECKOUT
        case .checkoutWithKlarna:
            return .CHECKOUT
//        case .addDirectDebitToVault:
//            return .VAULT
        case .vaultKlarna:
            return .VAULT
        case .primerWithVault:
            return .VAULT
        }
    }
}
