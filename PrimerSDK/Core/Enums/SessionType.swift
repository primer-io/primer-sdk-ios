//
//  SessionType.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

public enum PrimerSessionFlow {
    case completeDirectCheckout
    case completeVaultCheckout
    case addPayPalToVault
    case addCardToVault
    
    var vaulted: Bool {
        switch self {
        case .addCardToVault: return true
        case .addPayPalToVault: return true
        case .completeVaultCheckout: return true
        case .completeDirectCheckout: return false
        }
    }
    
    var uxMode: UXMode {
        switch self {
        case .addCardToVault: return .VAULT
        case .addPayPalToVault: return .VAULT
        case .completeVaultCheckout: return .VAULT
        case .completeDirectCheckout: return .CHECKOUT
        }
    }
    
}
