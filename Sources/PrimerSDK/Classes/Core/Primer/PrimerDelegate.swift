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

public typealias PaymentMethodTokenData = PaymentMethodToken

@objc
public protocol PrimerDelegate {
    
    func clientTokenCallback(_ completion: @escaping (_ token: String?, _ error: Error?) -> Void)
        
    /// This function will be called when the user tries to make a payment. You should make the pay API call to your backend, and
    /// pass an error or nil on completion. This way the SDK will show the error passed on the modal view controller.
    ///
    /// - Parameters:
    ///   - paymentMethodToken: The PaymentMethodToken object containing the token's information.
    ///   - completion: Call with error or nil when the pay API call returns a result.
    ///
    @available(*, deprecated, message: "Use primerDidCompleteCheckoutWithData(:) function")
    @objc optional func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodTokenData, _ completion:  @escaping (Error?) -> Void)
    
    @available(*, deprecated, message: "Use primerDidCompleteCheckoutWithData(:) function")
    @objc optional func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodTokenData, resumeHandler:  ResumeHandlerProtocol)
    
    @available(*, deprecated, message: "The resuming is now handled by the SDK internally so that the payment can either succeed or fail.\nSee primerDidCompleteCheckoutWithData(:) and primerDidFailWithError(:)")
    @objc optional func onResumeSuccess(_ clientToken: String, resumeHandler: ResumeHandlerProtocol)
    
    @available(*, deprecated, message: "Use SIMPLIFY DX!.")
    @objc optional func onResumeError(_ error: Error)
    
    @objc optional func primerDidDismiss()
    
    /// This function will be called when the user tries to make a payment. You should make the pay API call to your backend, and
    /// pass an error or nil on completion. This way the SDK will show the error passed on the modal view controller.
    /// Deprecated in favour of onTokenizeSuccess
    ///
    /// - Parameters:
    ///   - result: The PaymentMethodToken object containing the token's information.
    ///   - completion: Call with error or nil when the pay API call returns a result.
    @available(*, deprecated, renamed: "onTokenizeSuccess")
    @objc optional func authorizePayment(_ result: PaymentMethodTokenData, _ completion:  @escaping (Error?) -> Void)
    
    /// This function will be called when the SDK is about to initiate a client session update.
    @objc optional func primerClientSessionWillUpdate()
    
    /// This function will be called when the SDK finishes to update a client session.
    /// - Parameters:
    ///   - clientSession: The client session containing all the current info about the checkout.
    @objc optional func primerClientSessionDidUpdate(_ clientSession: CheckoutClientSessionData?)
    
    /// This function will be called when the SDK is about to initiate a payment.
    /// - Parameters:
    ///   - data: The payment method data containing the token's information.
    ///   - decisionHandler: The handler managing a custom error to optionally pass to the SDK
    @objc optional func primerWillCreatePaymentWithData(_ data: CheckoutPaymentMethodData, decisionHandler: @escaping (PaymentCreationDecision?) -> Void)
    
    /// This function will be called when the checkout has been successful.
    /// - Parameters:
    ///   - payment: The Payment object containing the completed payment.
    @objc optional func primerDidCompleteCheckoutWithData(_ data: CheckoutData)
    
    /// This function will be called when the checkout encountered an error.
    /// - Parameters:
    ///   - error: The Error object containing the error description.
    ///   - data: The additional payment data if present
    ///   - decisionHandler: The handler containing a custom error message to optionally pass to the SDK
    @objc optional func primerDidFailWithError(_ error: Error, data: CheckoutData?, decisionHandler: ((ErrorDecision?) -> Void)?)
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
    
    static func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodTokenData, _ completion:  @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.authorizePayment?(paymentMethodToken, completion)
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, completion)
        }
    }
    
    static func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodTokenData, resumeHandler:  ResumeHandlerProtocol) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, resumeHandler: resumeHandler)
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutTokenizationSucceeded(paymentMethodToken: paymentMethodToken, resumeHandler: resumeHandler)
        }
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
    
    static func primerWillCreatePaymentWithData(_ data: CheckoutPaymentMethodData, decisionHandler: @escaping (PaymentCreationDecision?) -> Void) {
        DispatchQueue.main.async {
            if Primer.shared.delegate?.primerWillCreatePaymentWithData != nil {
                Primer.shared.delegate?.primerWillCreatePaymentWithData?(data, decisionHandler: decisionHandler)
            } else {
                decisionHandler(nil)
            }
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
    
    static func primerDidCompleteCheckoutWithData(_ data: CheckoutData) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.primerDidCompleteCheckoutWithData?(data)
        }
    }
    
    static func primerDidFailWithError(_ error: Error, data: CheckoutData?, decisionHandler: ((ErrorDecision?) -> Void)?) {
        DispatchQueue.main.async {
            
            if Primer.shared.delegate?.primerDidFailWithError != nil {
                Primer.shared.delegate?.primerDidFailWithError?(error, data: data, decisionHandler: decisionHandler)
            } else if PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail != nil {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: error)
            } else {
                decisionHandler?(nil)
            }
        }
    }
    
    static func primerClientSessionWillUpdate() {
        DispatchQueue.main.async {
            Primer.shared.delegate?.primerClientSessionWillUpdate?()
        }
    }
    
    static func primerClientSessionDidUpdate(_ clientSession: CheckoutClientSessionData?) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.primerClientSessionDidUpdate?(clientSession)
        }
    }
    
    static func primerHeadlessUniversalCheckoutClientSessionDidSetUpSuccessfully() {
        
    }
    
    static func tokenizationPreparationStarted() {
        
    }
    
    static func primerHeadlessUniversalCheckoutPaymentMethodPresented() {
        
    }
    
    static func tokenizationSucceeded(paymentMethodToken: PaymentMethodTokenData, resumeHandler: ResumeHandlerProtocol?) {
        
    }
    
    static func primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError err: Error) {
        
    }
    
}

#endif
