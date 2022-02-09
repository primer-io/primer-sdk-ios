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
    
    @objc optional func tokenAddedToVault(_ token: PaymentMethodToken)
    
    /// This function will be called when the user tries to make a payment. You should make the pay API call to your backend, and
    /// pass an error or nil on completion. This way the SDK will show the error passed on the modal view controller.
    ///
    /// - Parameters:
    ///   - paymentMethodToken: The PaymentMethodToken object containing the token's information.
    ///   - completion: Call with error or nil when the pay API call returns a result.
    @objc optional func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void)
    @objc optional func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, resumeHandler:  ResumeHandlerProtocol)

    @objc optional func onResumeSuccess(_ clientToken: String, resumeHandler: ResumeHandlerProtocol)
    @objc optional func onResumeError(_ error: Error)
    
    @objc optional func onCheckoutDismissed()
    
    @objc optional func checkoutFailed(with error: Error)
    
    /// This function will be called when the user tries to make a payment. You should make the pay API call to your backend, and
    /// pass an error or nil on completion. This way the SDK will show the error passed on the modal view controller.
    /// Deprecated in favour of onTokenizeSuccess
    ///
    /// - Parameters:
    ///   - result: The PaymentMethodToken object containing the token's information.
    ///   - completion: Call with error or nil when the pay API call returns a result.
    @available(*, deprecated, renamed: "onTokenizeSuccess")
    @objc optional func authorizePayment(_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void)
    
    @objc optional func onClientSessionActions(_ actions: [ClientSession.Action], resumeHandler: ResumeHandlerProtocol?)
}

internal class PrimerDelegateProxy {
    
    static func clientTokenCallback(_ completion: @escaping (_ token: String?, _ error: Error?) -> Void) {4
        Primer.shared.delegate?.clientTokenCallback(completion)
    }
    
    static func tokenAddedToVault(_ token: PaymentMethodToken) {
        Primer.shared.delegate?.tokenAddedToVault?(token)
    }
    
    static func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) {
        if Primer.shared.flow.internalSessionFlow.vaulted {
            Primer.shared.delegate?.tokenAddedToVault?(paymentMethodToken)
        }
        Primer.shared.delegate?.authorizePayment?(paymentMethodToken, completion)
        Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, completion)
    }
    
    static func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, resumeHandler:  ResumeHandlerProtocol) {
        if Primer.shared.flow.internalSessionFlow.vaulted {
            Primer.shared.delegate?.tokenAddedToVault?(paymentMethodToken)
        }
        
        Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, resumeHandler: resumeHandler)
        PrimerCheckoutComponents.delegate?.onEvent(.tokenizationSucceeded(paymentMethodToken: paymentMethodToken, resumeHandler: resumeHandler))
    }
    
    static func onResumeSuccess(_ clientToken: String, resumeHandler: ResumeHandlerProtocol) {
        Primer.shared.delegate?.onResumeSuccess?(clientToken, resumeHandler: resumeHandler)
    }
    
    static func onResumeError(_ error: Error) {
        Primer.shared.delegate?.onResumeError?(error)
    }
    
    static func onCheckoutDismissed() {
        Primer.shared.delegate?.onCheckoutDismissed?()
    }
    
    static func checkoutFailed(with error: Error) {
        Primer.shared.delegate?.checkoutFailed?(with: error)
        PrimerCheckoutComponents.delegate?.onEvent(.failure(error: error))
    }
    
    static var isClientSessionActionsImplemented: Bool {
        return Primer.shared.delegate?.onClientSessionActions != nil
    }
    
    static func onClientSessionActions(_ actions: [ClientSession.Action], resumeHandler: ResumeHandlerProtocol?) -> Bool {
        if Primer.shared.delegate?.onClientSessionActions != nil {
            Primer.shared.delegate!.onClientSessionActions?(actions, resumeHandler: resumeHandler)
            return true
        } else {
            return false
        }
    }
    
    static func onEvent(_ event: PrimerCheckoutComponentsEvent) {
        switch event {
        case .clientSessionSetupSuccessfully,
                .preparationStarted,
                .paymentMethodPresented,
                .tokenizationStarted:
            PrimerCheckoutComponents.delegate?.onEvent(event)
        case .tokenizationSucceeded(let paymentMethodToken, let resumeHandler):
            PrimerCheckoutComponents.delegate?.onEvent(event)
            
            if let resumeHandler = resumeHandler {
                Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, resumeHandler: resumeHandler)
            }
        case .failure(let error):
            PrimerCheckoutComponents.delegate?.onEvent(event)
            Primer.shared.delegate?.checkoutFailed?(with: error)
        }
    }
}

internal class MockPrimerDelegate: PrimerDelegate {
    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        
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
