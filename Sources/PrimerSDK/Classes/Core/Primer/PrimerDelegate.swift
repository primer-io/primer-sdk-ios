#if canImport(UIKit)

import UIKit

/**
 Primer's required protocol. You need to conform to this protocol in order to take advantage of Primer's functionalities.
 
 It exposes three required methods, **clientTokenCallback**, **authorizePayment**, **primerDidDismiss**.
 
 *Values*
 
 `clientTokenCallback(_:)`: This function will be called once Primer can provide you a client token. Provide the token to
 your backend in order retrieve a session token.
 
 `tokenAddedToVault(_:)`: This function will be called only when a payment method has beed successfully added in vault.
 
 `authorizePayment(_:)`: This function will be called only on checkout flows. Use it to provide the payment method token to your backend and call the completion when your API is called is finished. Pass an error if needed.
 
 `primerDidDismiss(_:)`: This function notifies you when the drop-in UI is dismissed.
 
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
    @available(*, deprecated, message: "Use checkoutDidCompleteWithPayment(:) function")
    @objc optional func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void)
    
    @available(*, deprecated, message: "Use checkoutDidCompleteWithPayment(:) function")
    @objc optional func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, resumeHandler:  ResumeHandlerProtocol)

    @available(*, deprecated, message: "The resuming is now handled by the SDK internally so that the payment can either succeed or fail.\nSee checkoutDidCompleteWithPayment(:) and checkoutDidFail(:)")
    @objc optional func onResumeSuccess(_ clientToken: String, resumeHandler: ResumeHandlerProtocol)
    
    @available(*, deprecated, message: "Use SIMPLIFY DX!.")
    @objc optional func onResumeError(_ error: Error)
    
    @objc optional func primerDidDismiss()
    
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
    
    @objc optional func clientSessionUpdateDidStart()
    @objc optional func clientSessionUpdateDidFinish(clientSession: CheckoutDataClientSession)

    /// This function will be called when the SDK is about to initiate a payment.
    /// - Parameters:
    ///   - data: The payment method data containing the token's information.
    ///   - completion: The completion handler managing a custom error to optionally pass to the SDK
    @objc optional func primerWillCreatePaymentWithData(_ data: CheckoutPaymentMethodData, decisionHandler: @escaping (PaymentCreationDecision?) -> Void)
    
    /// This function will be called when the checkout has been successful.
    /// - Parameters:
    ///   - payment: The Payment object containing the completed payment.
    @objc optional func checkoutDidComplete(_ data: CheckoutData)
    
    /// This function will be called when the checkout encountered an error.
    /// - Parameters:
    ///   - error: The Error object containing the error description.
    ///   - payment: The additional payment data if present
    ///   - completion: The completion handler containing a custom error to optionally pass to the SDK
    @objc optional func checkoutDidFail(error: Error, data: CheckoutData?, completion: @escaping (String?) -> Void)
}

internal class PrimerDelegateProxy {
    
    static var isClientTokenCallbackImplemented: Bool {
        return Primer.shared.delegate?.clientTokenCallback != nil
    }
    
    static func clientTokenCallback(_ completion: @escaping (_ token: String?, _ error: Error?) -> Void) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.clientTokenCallback(completion)
        }
    }
    
    static var isTokenAddedToVaultImplemented: Bool {
        return Primer.shared.delegate?.tokenAddedToVault != nil
    }
    
    static func tokenAddedToVault(_ token: PaymentMethodToken) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.tokenAddedToVault?(token)
        }
    }
    
    static func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            if Primer.shared.flow.internalSessionFlow.vaulted {
                Primer.shared.delegate?.tokenAddedToVault?(paymentMethodToken)
            }
            Primer.shared.delegate?.authorizePayment?(paymentMethodToken, completion)
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, completion)
        }
    }
    
    static func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, resumeHandler:  ResumeHandlerProtocol) {
        DispatchQueue.main.async {
            if Primer.shared.flow.internalSessionFlow.vaulted {
                Primer.shared.delegate?.tokenAddedToVault?(paymentMethodToken)
            }
            
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, resumeHandler: resumeHandler)
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutTokenizationSucceeded(paymentMethodToken: paymentMethodToken, resumeHandler: resumeHandler)
        }
        Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, resumeHandler: resumeHandler)
        PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutTokenizationSucceeded(paymentMethodToken: paymentMethodToken, resumeHandler: resumeHandler)
    }
    
    static var isOnResumeSuccessImplemented: Bool {
        return Primer.shared.delegate?.onResumeSuccess != nil
    }
    
    static func onResumeSuccess(_ resumeToken: String, resumeHandler: ResumeHandlerProtocol) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.onResumeSuccess?(resumeToken, resumeHandler: resumeHandler)
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutResume(withResumeToken: resumeToken, resumeHandler: resumeHandler)
        }
    }
    
    static var isOnResumeErrorImplemented: Bool {
        return Primer.shared.delegate?.onResumeError != nil
    }
    
    static func onResumeError(_ error: Error) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.onResumeError?(error)
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: error)
        }
    }
    
    static var isOnCheckoutDismissedImplemented: Bool {
        return Primer.shared.delegate?.primerDidDismiss != nil
    }
    
    static func primerDidDismiss() {
        Primer.shared.delegate?.primerDidDismiss?()
    }
    
    static var isCheckoutFailedImplemented: Bool {
        return Primer.shared.delegate?.checkoutFailed != nil
    }
    
    static func checkoutFailed(with error: Error) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.checkoutFailed?(with: error)
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: error)
        }
    }
    
    static var isClientSessionActionsImplemented: Bool {
        let state: AppStateProtocol = DependencyContainer.resolve()
        if let implementedReactNativeCallbacks = state.implementedReactNativeCallbacks {
            return implementedReactNativeCallbacks.isClientSessionActionsImplemented == true
        }
        let isClientSessionActionDidStartImplemented = Primer.shared.delegate?.clientSessionUpdateDidStart != nil
        let isClientSessionActionDidFinishImplemented = Primer.shared.delegate?.clientSessionUpdateDidFinish != nil
        return isClientSessionActionDidStartImplemented || isClientSessionActionDidFinishImplemented
    }
    
    static func clientSessionUpdateDidStart() {
        if PrimerDelegateProxy.isClientSessionActionsImplemented {
            Primer.shared.delegate?.clientSessionUpdateDidStart?()
        }
    }
    static func clientSessionUpdateDidFinish(clientSession: CheckoutDataClientSession) {
        if PrimerDelegateProxy.isClientSessionActionsImplemented {
            Primer.shared.delegate?.clientSessionUpdateDidFinish?(clientSession: clientSession)
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

    func primerDidDismiss() {

    }
    
    func checkoutFailed(with error: Error) {
        
    }
    
}

#endif
