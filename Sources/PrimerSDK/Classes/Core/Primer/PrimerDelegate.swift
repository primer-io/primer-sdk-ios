#if canImport(UIKit)

import UIKit

/**
 Primer's required protocol. You need to conform to this protocol in order to take advantage of Primer's functionalities.
 
 It exposes three required methods, **clientTokenCallback**, **authorizePayment**, **onCheckoutDismissed**.
 
 *Values*
 
 `clientTokenCallback(_:)`: This function will be called once Primer can provide you a client token. Provide the token to
 your backend in order retrieve a session token.
 
 `tokenAddedToVault(_:)`: This function will be called only when a payment method has beed successfully added in vault.
 
 `authorizePayment(_:)`: This function will be called only on checkout flows. Use it to provide the payment method token to your backend and call the completion when your API is called is finished. Pass an error if needed.
 
 `onCheckoutDismissed(_:)`: This function notifies you when the drop-in UI is dismissed.
 
 - Author:
 Primer
 - Version:
 1.4.3
 */

public protocol PrimerDelegate: class {
    func clientTokenCallback(_ completion: @escaping (Result<String, Error>) -> Void)
    func tokenAddedToVault(_ token: PaymentMethodToken)
    @available(*, deprecated, renamed: "onTokenizeSuccess")
    func authorizePayment(_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void)
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void)
    func onCheckoutDismissed()
    func checkoutFailed(with error: Error)
}

internal class MockPrimerDelegate: PrimerDelegate {
    func clientTokenCallback(_ completion: @escaping (Result<String, Error>) -> Void) {

    }
    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
        
    }

    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {

    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        
    }

    func onCheckoutDismissed() {

    }
    
    func checkoutFailed(with error: Error) {
        
    }
    
}

#endif
