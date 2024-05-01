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

internal class PrimerDelegateProxy: LogReporter {

    static func primerDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecisionProtocol) -> Void) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless,
               (decisionHandler as ((PrimerHeadlessUniversalCheckoutResumeDecision) -> Void)?) != nil {
                let delegate = PrimerHeadlessUniversalCheckout.current.delegate
                delegate?.primerHeadlessUniversalCheckoutDidTokenizePaymentMethod?(paymentMethodTokenData,
                                                                                   decisionHandler: decisionHandler)

            } else if PrimerInternal.shared.sdkIntegrationType == .dropIn,
                      (decisionHandler as ((PrimerResumeDecision) -> Void)?) != nil {
                Primer.shared.delegate?.primerDidTokenizePaymentMethod?(paymentMethodTokenData, decisionHandler: decisionHandler)
            }
        }
    }

    static func primerDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecisionProtocol) -> Void) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless,
               (decisionHandler as ((PrimerHeadlessUniversalCheckoutResumeDecision) -> Void)?) != nil {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidResumeWith?(resumeToken,
                                                                                                                decisionHandler: decisionHandler)
            } else if PrimerInternal.shared.sdkIntegrationType == .dropIn,
                      (decisionHandler as ((PrimerResumeDecision) -> Void)?) != nil {
                Primer.shared.delegate?.primerDidResumeWith?(resumeToken, decisionHandler: decisionHandler)
            }
        }
    }

    static func primerWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                let delegate = PrimerHeadlessUniversalCheckout.current.delegate
                if delegate?.primerHeadlessUniversalCheckoutWillCreatePaymentWithData != nil {
                    delegate?.primerHeadlessUniversalCheckoutWillCreatePaymentWithData?(data,
                                                                                        decisionHandler: decisionHandler)
                } else {
                    decisionHandler(.continuePaymentCreation())
                }

            } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                if Primer.shared.delegate?.primerWillCreatePaymentWithData != nil {
                    Primer.shared.delegate?.primerWillCreatePaymentWithData?(data, decisionHandler: decisionHandler)
                } else {
                    decisionHandler(.continuePaymentCreation())
                }
            }
        }
    }

    static func primerDidDismiss(paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory]) {
        print(">> PRIMER DID DISMISS")
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                Primer.shared.delegate?.primerDidDismiss?()
            } else if paymentMethodManagerCategories.contains(.nativeUI) {
                PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniveraslCheckoutUIDidDismissPaymentMethod?()
            }
        }
    }

    static func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(data)

                if let timingEventId = PrimerHeadlessUniversalCheckout.current.timingEventId,
                   PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData != nil {
                    let timingEndEvent = Analytics.Event.timer(
                        momentType: .start,
                        id: timingEventId
                    )

                    Analytics.Service.record(events: [timingEndEvent])
                }

                PrimerUIManager.dismissPrimerUI(animated: true)

            } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                Primer.shared.delegate?.primerDidCompleteCheckoutWithData(data)
            }
        }
    }

    static func primerDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                let delegate = PrimerHeadlessUniversalCheckout.current.delegate
                delegate?.primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo?(additionalInfo)

            } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                Primer.shared.delegate?.primerDidEnterResumePendingWithPaymentAdditionalInfo?(additionalInfo)
            }
        }
    }

    static func primerDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo?(additionalInfo)
            }
        }
    }

    static func primerDidAbortPayment(error: Error) {
        DispatchQueue.main.async {
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidAbort?(withMerchantError: error)
        }
    }

    static func primerDidFailWithError(_ error: any PrimerErrorProtocol, data: PrimerCheckoutData?, decisionHandler: @escaping ((PrimerErrorDecision) -> Void)) {
        DispatchQueue.main.async {

            if case .merchantError = (error as? PrimerError) {
                decisionHandler(.fail(withErrorMessage: error.errorDescription))
                return
            }

            let exposedError: Error = error.exposedError

            if PrimerInternal.shared.sdkIntegrationType == .headless {
                if PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail == nil {
                    logger.warn(message: "Delegate function 'primerHeadlessUniversalCheckoutDidFail' hasn't been implemented.")
                    decisionHandler(.fail(withErrorMessage: nil))

                } else {
                    let delegate = PrimerHeadlessUniversalCheckout.current.delegate
                    delegate?.primerHeadlessUniversalCheckoutDidFail!(withError: exposedError,
                                                                      checkoutData: data)
                    decisionHandler(.fail(withErrorMessage: nil))
                }

                if let timingEventId = PrimerHeadlessUniversalCheckout.current.timingEventId,
                   PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData != nil {
                    let timingEndEvent = Analytics.Event.timer(
                        momentType: .end,
                        id: timingEventId
                    )

                    Analytics.Service.record(events: [timingEndEvent])
                    Analytics.Service.flush()
                }

                PrimerUIManager.dismissPrimerUI(animated: true)

            } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                if Primer.shared.delegate?.primerDidFailWithError == nil {
                    let message = """
Delegate function 'primerDidFailWithError' hasn't been implemented.\
No custom error message will be displayed on the error screen.
"""
                    logger.warn(message: message)
                    decisionHandler(.fail(withErrorMessage: nil))

                } else {
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
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutWillUpdateClientSession?()

            } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                Primer.shared.delegate?.primerClientSessionWillUpdate?()
            }
        }
    }

    static func primerClientSessionDidUpdate(_ clientSession: PrimerClientSession) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidUpdateClientSession?(clientSession)
            } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                Primer.shared.delegate?.primerClientSessionDidUpdate?(clientSession)
            }
        }
    }

    static func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods?(paymentMethods)
            }
        }
    }

    static func primerHeadlessUniversalCheckoutUIDidStartPreparation(for paymentMethodType: String) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidStartPreparation?(for: paymentMethodType)
            }
        }
    }

    static func primerHeadlessUniversalCheckoutDidStartTokenization(for paymentMethodType: String) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidStartTokenization?(for: paymentMethodType)
            }
        }
    }

    static func primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for paymentMethodType: String) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod?(for: paymentMethodType)
            }
        }
    }
}
