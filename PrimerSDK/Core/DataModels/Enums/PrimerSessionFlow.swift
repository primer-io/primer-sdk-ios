//
//  SessionType.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

public enum PrimerSessionFlow {
    case completeDirectCheckout
    case `default`
    case addPayPalToVault
    case addCardToVault
    case addDirectDebit
    case checkoutWithKlarna
    
    var vaulted: Bool {
        switch self {
        case .addCardToVault: return true
        case .addPayPalToVault: return true
        case .default: return true
        case .addDirectDebit: return true
        case .completeDirectCheckout: return false
        case .checkoutWithKlarna: return true
        }
    }
    var uxMode: UXMode {
        switch self {
        case .addCardToVault: return .VAULT
        case .addPayPalToVault: return .VAULT
        case .default: return .VAULT
        case .addDirectDebit: return .VAULT
        case .completeDirectCheckout: return .CHECKOUT
        case .checkoutWithKlarna: return .CHECKOUT
        }
    }
}
