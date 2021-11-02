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
    case checkoutWithAsyncPaymentMethod(paymentMethodType: PaymentMethodConfigType)

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
        case .checkoutWithPayPal:
            return .checkoutWithPayPal
        case .checkoutWithAsyncPaymentMethod:
            return .checkoutWithAsyncPaymentMethod
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
    case checkoutWithAsyncPaymentMethod
    case checkoutWithKlarna
    case checkoutWithPayPal
    
    
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
             .checkoutWithAsyncPaymentMethod,
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
             .checkoutWithAsyncPaymentMethod,
             .checkoutWithPayPal,
             .checkoutWithKlarna,
             .checkoutWithApplePay:
            return .CHECKOUT
        }
    }
}

public enum PrimerSessionIntent: String {
    case checkout
    case vault
}

#endif
