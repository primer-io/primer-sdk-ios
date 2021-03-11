//
//  SessionType.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

public enum PrimerSessionFlow {
    case completeDirectCheckout
    case `default`
    case defaultWithVault
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
            return true
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
