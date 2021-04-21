#if canImport(UIKit)

import UIKit

/**
 Primer's required protocol. You need to conform to this protocol in order to take advantage of Primer's functionalities.
 
 It exposes three required methods, **clientTokenCallback**, **authorizePayment**, **onCheckoutDismissed**.
 
 *Values*
 
 `clientTokenCallback(_:)`: This function will be called once Primer can provide you a client token. Provide the token to
 your backend in order retrieve a session token.
 
 `authorizePayment(_:)`: This function will return a token for any selected payment method. Provide this token to your backend
 in order to authorize the payment.
 
 `onCheckoutDismissed(_:)`: This function notifies you when the drop-in UI is dismissed.
 
 - Author:
 Primer
 - Version:
 1.2.2
 */

public protocol PrimerDelegate: class {
    func clientTokenCallback(_ completion: @escaping (Result<CreateClientTokenResponse, Error>) -> Void)
    func tokenAddedToVault(_ token: String)
    func authorizePayment(_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void)
    func onCheckoutDismissed()
}

class MockPrimerDelegate: PrimerDelegate {
    
    func clientTokenCallback(_ completion: @escaping (Result<CreateClientTokenResponse, Error>) -> Void) {

    }
    
    func tokenAddedToVault(_ token: String) {
        
    }

    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {

    }

    func onCheckoutDismissed() {

    }
}

#endif
