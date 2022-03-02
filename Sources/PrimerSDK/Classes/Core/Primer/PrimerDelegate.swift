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
    ///
    @available(*, deprecated, message: "Use onPaymentSuccess(:) function")
    @objc optional func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void)
    
    @available(*, deprecated, message: "Use onPaymentSuccess(:) function")
    @objc optional func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, resumeHandler:  ResumeHandlerProtocol)

    @available(*, deprecated, message: "The resuming is now handled by the SDK internally so that the payment can either succeed or fail.\nSee onPaymentSuccess(:) and onPaymentError(:)")
    @objc optional func onResumeSuccess(_ clientToken: String, resumeHandler: ResumeHandlerProtocol)
    
    @available(*, deprecated, message: "Use SIMPLIFY DX!.")
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
    
    // mock payment started
    // cannot use "strucs" because of ObjectiveC - so fallback to standard types
    // check FormTokenizationViewModel func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethodToken: PaymentMethodToken) {
    
    /// This function will be called when the user initiate a payment.
    /// - Parameters:
    ///   - paymentMethodToken: The PaymentMethodToken object containing the token's information.
    @objc optional func onPaymentStarted(_ paymentMethodToken: String)
    
    /// This function will be called when the user receives a payment object in a PENDING status.
    /// - Parameters:
    ///   - payment: The Payment object containing the current payment status.
    @objc optional func onPaymentPending(_ payment: [String: Any])

    /// This function will be called when the payment has been successful.
    /// - Parameters:
    ///   - payment: The Payment object containing the completed payment.
    @objc optional func onPaymentSuccess(_ payment: [String: Any])
    
    /// This function will be called when the payment encountered an error.
    /// - Parameters:
    ///   - error: The Error object containing the error description.
    @objc optional func onPaymentError(_ error: Error)
}

internal class PrimerDelegateProxy {
    
    static var isClientTokenCallbackImplemented: Bool {
        return Primer.shared.delegate?.clientTokenCallback != nil
    }
    
    static func clientTokenCallback(_ completion: @escaping (_ token: String?, _ error: Error?) -> Void) {
        Primer.shared.delegate?.clientTokenCallback(completion)
    }
    
    static var isTokenAddedToVaultImplemented: Bool {
        return Primer.shared.delegate?.tokenAddedToVault != nil
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
        PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutTokenizationSucceeded(paymentMethodToken: paymentMethodToken, resumeHandler: resumeHandler)
    }
    
    static var isOnResumeSuccessImplemented: Bool {
        return Primer.shared.delegate?.onResumeSuccess != nil
    }
    
    static func onResumeSuccess(_ resumeToken: String, resumeHandler: ResumeHandlerProtocol) {
        Primer.shared.delegate?.onResumeSuccess?(resumeToken, resumeHandler: resumeHandler)
        PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutResume(withResumeToken: resumeToken, resumeHandler: resumeHandler)
    }
    
    static var isOnResumeErrorImplemented: Bool {
        return Primer.shared.delegate?.onResumeError != nil
    }
    
    static func onResumeError(_ error: Error) {
        Primer.shared.delegate?.onResumeError?(error)
        PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: error)
    }
    
    static var isOnCheckoutDismissedImplemented: Bool {
        return Primer.shared.delegate?.onCheckoutDismissed != nil
    }
    
    static func onCheckoutDismissed() {
        Primer.shared.delegate?.onCheckoutDismissed?()
    }
    
    static var isCheckoutFailedImplemented: Bool {
        return Primer.shared.delegate?.checkoutFailed != nil
    }
    
    static func checkoutFailed(with error: Error) {
        Primer.shared.delegate?.checkoutFailed?(with: error)
        PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: error)
    }
    
    static var isClientSessionActionsImplemented: Bool {
        let state: AppStateProtocol = DependencyContainer.resolve()
        if let implementedReactNativeCallbacks = state.implementedReactNativeCallbacks {
            return implementedReactNativeCallbacks.isClientSessionActionsImplemented == true
        }
        return Primer.shared.delegate?.onClientSessionActions != nil
    }
    
    static func onClientSessionActions(_ actions: [ClientSession.Action], resumeHandler: ResumeHandlerProtocol?) {
        if PrimerDelegateProxy.isClientSessionActionsImplemented {
            Primer.shared.delegate!.onClientSessionActions?(actions, resumeHandler: resumeHandler)
        }
    }
    
    static func primerHeadlessUniversalCheckoutClientSessionDidSetUpSuccessfully() {
        
    }
    
    static func tokenizationPreparationStarted() {
        
    }
    
    static func primerHeadlessUniversalCheckoutPaymentMethodPresented() {
        
    }
    
    static func tokenizationSucceeded(paymentMethodToken: PaymentMethodToken, resumeHandler: ResumeHandlerProtocol?) {
        
    }
    
    static func primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError err: Error) {

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
