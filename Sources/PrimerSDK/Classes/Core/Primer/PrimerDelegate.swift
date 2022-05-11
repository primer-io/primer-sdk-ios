#if canImport(UIKit)

import UIKit

public typealias PrimerPaymentMethodTokenData = PaymentMethodToken

@objc
public protocol PrimerDelegate {
    
    // MARK: Required
    
    /// This function will be called when the checkout has been successful.
    /// - Parameters:
    ///   - payment: The Payment object containing the completed payment.
    @objc func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData)
    
    // MARK: Optional
    
    /// This function will be called when the SDK is about to initiate a client session update.
    @objc optional func primerClientSessionWillUpdate()
    /// This function will be called when the SDK finishes to update a client session.
    /// - Parameters:
    ///   - clientSession: The client session containing all the current info about the checkout.
    @objc optional func primerClientSessionDidUpdate(_ clientSession: PrimerClientSession)
    /// This function will be called when the SDK is about to initiate a payment.
    /// - Parameters:
    ///   - data: The payment method data containing the token's information.
    ///   - decisionHandler: The handler managing a custom error to optionally pass to the SDK
    @objc optional func primerWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void)
    
    /// This function will be called when the checkout encountered an error.
    /// - Parameters:
    ///   - error: The Error object containing the error description.
    ///   - data: The additional payment data if present
    ///   - decisionHandler: The handler containing a custom error message to optionally pass to the SDK
    @objc optional func primerDidFailWithError(_ error: Error, data: PrimerCheckoutData?, decisionHandler: @escaping ((PrimerErrorDecision) -> Void))
    @objc optional func primerDidDismiss()
        
    @objc optional func primerDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void)
    @objc optional func primerDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void)
}

internal class PrimerDelegateProxy {
    
    static func primerDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
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
    
    static func primerWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        DispatchQueue.main.async {
            if Primer.shared.delegate?.primerWillCreatePaymentWithData != nil {
                Primer.shared.delegate?.primerWillCreatePaymentWithData?(data, decisionHandler: decisionHandler)
            } else {
                decisionHandler(.continuePaymentCreation())
            }
        }
    }
    
    static var isOnCheckoutDismissedImplemented: Bool {
        return Primer.shared.delegate?.primerDidDismiss != nil
    }
    
    static func primerDidDismiss() {
        Primer.shared.delegate?.primerDidDismiss?()
    }
    
    static func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.primerDidCompleteCheckoutWithData(data)
        }
    }
    
    static func primerDidFailWithError(_ error: PrimerError, data: PrimerCheckoutData?, decisionHandler: @escaping ((PrimerErrorDecision) -> Void)) {
        DispatchQueue.main.async {
            if Primer.shared.delegate?.primerDidFailWithError != nil {
                Primer.shared.delegate?.primerDidFailWithError?(error.exposedError, data: data, decisionHandler: { errorDecision in
                    switch errorDecision.type {
                    case .fail(let message):
                        DispatchQueue.main.async {
                            decisionHandler(.fail(withErrorMessage: message))
                        }
                    }
                })
            } else {
                print("WARNING: Delegate function '\(#function)' hasn't been implemented. No custom error message will be displayed on the error screen.")
                decisionHandler(.fail(withErrorMessage: nil))
            }
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: error)
        }
    }
    
    // This function will raise the error to the merchants, and the merchants will
    // return the error message they want to present.
    static func raisePrimerDidFailWithError(_ primerError: PrimerError, data: PrimerCheckoutData?) -> Promise<String?> {
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
    
    static func primerClientSessionDidUpdate(_ clientSession: PrimerClientSession) {
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
