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

    case `default`
    case defaultWithVault
    case completeDirectCheckout
    case addPayPalToVault
    case addCardToVault
    case addDirectDebitToVault
    case addKlarnaToVault
    case addDirectDebit
    case checkoutWithKlarna

    var vaulted: Bool {
        switch self {
        case .addCardToVault:
            return true
        case .addPayPalToVault:
            return true
        case .default:
            return false
        case .addDirectDebit:
            return true
        case .completeDirectCheckout:
            return false
        case .checkoutWithKlarna:
            return false
        case .addDirectDebitToVault:
            return true
        case .addKlarnaToVault:
            return true
        case .defaultWithVault:
            return true
        }
    }

    var uxMode: UXMode {
        switch self {
        case .addCardToVault:
            return .VAULT
        case .addPayPalToVault:
            return .VAULT
        case .default:
            return .CHECKOUT
        case .addDirectDebit:
            return .VAULT
        case .completeDirectCheckout:
            return .CHECKOUT
        case .checkoutWithKlarna:
            return .CHECKOUT
        case .addDirectDebitToVault:
            return .VAULT
        case .addKlarnaToVault:
            return .VAULT
        case .defaultWithVault:
            return .VAULT
        }
    }
}
