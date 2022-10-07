#if canImport(UIKit)

import UIKit

public typealias PrimerPaymentMethodTokenData = Response.Body.Tokenization

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
    @objc optional func primerDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?)
}

internal class PrimerDelegateProxy {
    
    static func primerDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecisionProtocol) -> Void) {
        DispatchQueue.main.async {
            if PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidTokenizePaymentMethod != nil,
               (decisionHandler as ((PrimerHeadlessUniversalCheckoutResumeDecision) -> Void)?) != nil
            {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidTokenizePaymentMethod!(paymentMethodTokenData, decisionHandler: decisionHandler)
                return
            }
            
            if Primer.shared.delegate?.primerDidTokenizePaymentMethod != nil,
               (decisionHandler as ((PrimerResumeDecision) -> Void)?) != nil
            {
                Primer.shared.delegate?.primerDidTokenizePaymentMethod?(paymentMethodTokenData, decisionHandler: decisionHandler)
                return
            }
        }
    }
    
    static func primerDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecisionProtocol) -> Void) {
        DispatchQueue.main.async {
            if PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidResumeWith != nil,
               (decisionHandler as ((PrimerHeadlessUniversalCheckoutResumeDecision) -> Void)?) != nil
            {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidResumeWith!(resumeToken, decisionHandler: decisionHandler)
                return
            }
            
            if Primer.shared.delegate?.primerDidResumeWith != nil,
               (decisionHandler as ((PrimerResumeDecision) -> Void)?) != nil
            {
                Primer.shared.delegate?.primerDidResumeWith?(resumeToken, decisionHandler: decisionHandler)
                return
            }
        }
    }
    
    static func primerWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        DispatchQueue.main.async {
            if Primer.shared.delegate?.primerWillCreatePaymentWithData != nil || PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutWillCreatePaymentWithData != nil {
                Primer.shared.delegate?.primerWillCreatePaymentWithData?(data, decisionHandler: decisionHandler)
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutWillCreatePaymentWithData?(data, decisionHandler: decisionHandler)
            } else {
                decisionHandler(.continuePaymentCreation())
            }
        }
    }
    
    static var isOnCheckoutDismissedImplemented: Bool {
        return Primer.shared.delegate?.primerDidDismiss != nil
    }
    
    static func primerDidDismiss() {
        DispatchQueue.main.async {
            Primer.shared.delegate?.primerDidDismiss?()
        }
    }
    
    static func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.primerDidCompleteCheckoutWithData(data)
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(data)
        }
    }
    
    static func primerDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.primerDidEnterResumePendingWithPaymentAdditionalInfo?(additionalInfo)
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo?(additionalInfo)
        }
    }
    
    static func primerDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo) {
        DispatchQueue.main.async {
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo?(additionalInfo)
        }
    }
    
    static func primerDidFailWithError(_ error: PrimerErrorProtocol, data: PrimerCheckoutData?, decisionHandler: @escaping ((PrimerErrorDecision) -> Void)) {
        DispatchQueue.main.async {
            if case .sdkDismissed = (error as? PrimerError) {
                // Don't send an error, the primerDidDismiss has been called.
                return
            }
            
            if case .merchantError = (error as? PrimerError) {
                decisionHandler(.fail(withErrorMessage: error.errorDescription))
                return
            }
            
            let exposedError: Error = error.exposedError
            
            if Primer.shared.delegate?.primerDidFailWithError == nil,
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail == nil
            {
                print("WARNING!\nDelegate function '\(#function)' hasn't been implemented. No custom error message will be displayed on the error screen.")
                decisionHandler(.fail(withErrorMessage: nil))
                return
            }
            
            if PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail != nil {
                DispatchQueue.main.async {
                    PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail!(withError: exposedError, checkoutData: data)
                    decisionHandler(.fail(withErrorMessage: nil))
                }
                
            } else if Primer.shared.delegate?.primerDidFailWithError != nil {
                Primer.shared.delegate?.primerDidFailWithError?(exposedError, data: data, decisionHandler: { errorDecision in
                    switch errorDecision.type {
                    case .fail(let message):
                        DispatchQueue.main.async {
                            decisionHandler(.fail(withErrorMessage: message))
                        }
                    }
                })
                
            }
        }
    }
    
    // This function will raise the error to the merchants, and the merchants will
    // return the error message they want to present.
    @discardableResult
    static func raisePrimerDidFailWithError(_ primerError: PrimerError, data: PrimerCheckoutData?) -> Promise<String?> {
        return Promise { seal in
            DispatchQueue.main.async {
                PrimerDelegateProxy.primerDidFailWithError(primerError, data: data) { errorDecision in
                    switch errorDecision.type {
                    case .fail(let message):
                        seal.fulfill(message)
                    }
                }
            }
        }
    }
    
    static func primerClientSessionWillUpdate() {
        DispatchQueue.main.async {
            Primer.shared.delegate?.primerClientSessionWillUpdate?()
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutWillUpdateClientSession?()
        }
    }
    
    static func primerClientSessionDidUpdate(_ clientSession: PrimerClientSession) {
        DispatchQueue.main.async {
            Primer.shared.delegate?.primerClientSessionDidUpdate?(clientSession)
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidUpdateClientSession?(clientSession)
        }
    }
    
    static func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]) {
        DispatchQueue.main.async {
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods?(paymentMethods)
        }
    }
    
    static func primerHeadlessUniversalCheckoutUIDidStartPreparation(for paymentMethodType: String) {
        DispatchQueue.main.async {
            PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidStartPreparation?(for: paymentMethodType)
        }
    }
    
    static func primerHeadlessUniversalCheckoutDidStartTokenization(for paymentMethodType: String) {
        DispatchQueue.main.async {
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidStartTokenization?(for: paymentMethodType)
        }
    }
    
    static func primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for paymentMethodType: String) {
        DispatchQueue.main.async {
            PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod?(for: paymentMethodType)
        }
    }
}

#endif
