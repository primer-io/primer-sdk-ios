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

@objc
public protocol PrimerDelegate {
    
    func clientTokenCallback(_ completion: @escaping (_ token: String?, _ error: Error?) -> Void)
    
    @objc optional func tokenAddedToVault(_ token: PaymentMethod)
    
    /// This function will be called when the user tries to make a payment. You should make the pay API call to your backend, and
    /// pass an error or nil on completion. This way the SDK will show the error passed on the modal view controller.
    ///
    /// - Parameters:
    ///   - paymentMethodToken: The PaymentInstrument object containing the token's information.
    ///   - completion: Call with error or nil when the pay API call returns a result.
//    @available(*, deprecated, renamed: "onTokenizeSuccess")
//    @objc optional func onTokenizeSuccess(_ paymentMethodToken: PaymentMethod, _ completion:  @escaping (Error?) -> Void)
    @objc optional func onTokenizeSuccess(_ paymentMethod: PaymentMethod, _ completion:  @escaping (Error?) -> Void)
    
    @objc optional func onCheckoutDismissed()
    
    @objc optional func checkoutFailed(with error: Error)
    
    /// This function will be called when the user tries to make a payment. You should make the pay API call to your backend, and
    /// pass an error or nil on completion. This way the SDK will show the error passed on the modal view controller.
    /// Deprecated in favour of onTokenizeSuccess
    ///
    /// - Parameters:
    ///   - result: The PaymentInstrument object containing the token's information.
    ///   - completion: Call with error or nil when the pay API call returns a result.
    @available(*, deprecated, renamed: "onTokenizeSuccess")
    @objc optional func authorizePayment(_ result: PaymentMethod, _ completion:  @escaping (Error?) -> Void)
    
}

internal class MockPrimerDelegate: PrimerDelegate {
    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        
    }
    
    func tokenAddedToVault(_ token: PaymentMethod) {
        
    }

    func authorizePayment(_ result: PaymentMethod, _ completion: @escaping (Error?) -> Void) {

    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethod, _ completion: @escaping (Error?) -> Void) {
        
    }

    func onCheckoutDismissed() {

    }
    
    func checkoutFailed(with error: Error) {
        
    }
    
}

#endif
