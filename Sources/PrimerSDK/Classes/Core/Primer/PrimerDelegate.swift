#if canImport(UIKit)

import UIKit

/**
 Primer's required protocol. You need to conform to this protocol in order to take advantage of Primer's functionalities.
 
 It exposes three required methods, **clientTokenCallback**, **authorizePayment**, **primerDidDismiss**.
 
 *Values*
 
 `clientTokenCallback(_:)`: This function will be called once Primer can provide you a client token. Provide the token to
 your backend in order retrieve a session token.
  
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
    
    // MARK: Required
    
    /// This function will be called when the checkout has been successful.
    /// - Parameters:
    ///   - payment: The Payment object containing the completed payment.
    @objc func primerDidCompleteCheckoutWithData(_ data: CheckoutData)
    
    // MARK: Optional
    
    @objc optional func clientTokenCallback(_ completion: @escaping (_ token: String?, _ error: Error?) -> Void)
    
    @available(*, deprecated, message: "Use primerDidCompleteCheckoutWithData(:) function")
    @objc optional func primerDidTokenizePaymentMethod(_ paymentMethodTokenData: PaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void)
    @available(*, deprecated, message: "Use primerDidCompleteCheckoutWithData(:) function")
    @objc optional func primerDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void)
    
    
    @objc optional func primerDidDismiss()
    
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
    @objc optional func primerWillCreatePaymentWithData(_ data: CheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision?) -> Void)
    
    /// This function will be called when the checkout encountered an error.
    /// - Parameters:
    ///   - error: The Error object containing the error description.
    ///   - data: The additional payment data if present
    ///   - decisionHandler: The handler containing a custom error message to optionally pass to the SDK
    @objc optional func primerDidFailWithError(_ error: Error, data: CheckoutData?, decisionHandler: @escaping ((PrimerErrorDecision) -> Void))
}

internal class PrimerDelegateProxy {
    
    static var isClientTokenCallbackImplemented: Bool {
        return Primer.shared.delegate?.clientTokenCallback != nil
    }
    
    static func clientTokenCallback(_ completion: @escaping (_ token: String?, _ error: Error?) -> Void) {
        DispatchQueue.main.async {
            if isClientTokenCallbackImplemented {
                Primer.shared.delegate?.clientTokenCallback?(completion)
            } else {
                let state: AppStateProtocol = DependencyContainer.resolve()
                if let clientToken = state.clientToken {
                    completion(clientToken, nil)
                } else {
                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    completion(nil, err)
                }
            }
        }
    }
    
    static func primerDidTokenizePaymentMethod(_ paymentMethodTokenData: PaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        DispatchQueue.main.async {
            if Primer.shared.delegate?.primerDidTokenizePaymentMethod != nil {
                Primer.shared.delegate?.primerDidTokenizePaymentMethod?(paymentMethodTokenData, decisionHandler: decisionHandler)
            }
//            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutTokenizationSucceeded(paymentMethodToken: paymentMethodToken, resumeHandler: resumeHandler)
        }
    }
    
    static func primerDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        DispatchQueue.main.async {
            if Primer.shared.delegate?.primerDidResumeWith != nil {
                Primer.shared.delegate?.primerDidResumeWith?(resumeToken, decisionHandler: decisionHandler)
            }
        }
    }
    
    static func primerWillCreatePaymentWithData(_ data: CheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision?) -> Void) {
        DispatchQueue.main.async {
            if Primer.shared.delegate?.primerWillCreatePaymentWithData != nil {
                Primer.shared.delegate?.primerWillCreatePaymentWithData?(data, decisionHandler: decisionHandler)
            } else {
                decisionHandler(nil)
            }
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
            Primer.shared.delegate?.primerDidCompleteCheckoutWithData(data)
        }
    }
    
    static func primerDidFailWithError(_ error: Error, data: CheckoutData?, decisionHandler: @escaping ((PrimerErrorDecision) -> Void)) {
        DispatchQueue.main.async {
            if Primer.shared.delegate?.primerDidFailWithError != nil {
                Primer.shared.delegate?.primerDidFailWithError?(error, data: data, decisionHandler: { errorDecision in
                    switch errorDecision.type {
                    case .fail(let message):
                        DispatchQueue.main.async {
                            decisionHandler(.fail(withMessage: message))
                        }
                    }
                })
            } else {
                print("WARNING: Delegate function '\(#function)' hasn't been implemented. No custom error message will be displayed on the error screen.")
                decisionHandler(.fail(withMessage: nil))
            }
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: error)
        }
    }
    
    // This function will raise the error to the merchants, and the merchants will
    // return the error message they want to present.
    static func raisePrimerDidFailWithError(_ primerError: Error, data: CheckoutData?) -> Promise<String?> {
        return Promise { seal in
            PrimerDelegateProxy.primerDidFailWithError(primerError, data: data) { errorDecision in
                switch errorDecision.type {
                case .fail(let message):
                    seal.fulfill(message)
                }
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
    
    static func primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError err: Error) {
        
    }
    
}

#endif
