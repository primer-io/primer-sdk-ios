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
    @objc optional func primerWillCreatePaymentWithData(
        _ data: PrimerCheckoutPaymentMethodData,
        decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void
    )

    /// This function will be called when the checkout encountered an error.
    /// - Parameters:
    ///   - error: The Error object containing the error description.
    ///   - data: The additional payment data if present
    ///   - decisionHandler: The handler containing a custom error message to optionally pass to the SDK
    @objc optional func primerDidFailWithError(_ error: Error, data: PrimerCheckoutData?, decisionHandler: @escaping ((PrimerErrorDecision) -> Void))
    @objc optional func primerDidDismiss()

    @objc optional func primerDidTokenizePaymentMethod(
        _ paymentMethodTokenData: PrimerPaymentMethodTokenData,
        decisionHandler: @escaping (PrimerResumeDecision) -> Void
    )
    @objc optional func primerDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void)
    @objc optional func primerDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?)
}

final class PrimerDelegateProxy: LogReporter {
    static func primerDidTokenizePaymentMethod(
        _ paymentMethodTokenData: PrimerPaymentMethodTokenData,
        decisionHandler: @escaping (PrimerResumeDecisionProtocol) -> Void
    ) {
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

    @MainActor
    static func primerDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData) async -> PrimerResumeDecisionProtocol {
        await withCheckedContinuation { continuation in
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.delegate?
                    .primerHeadlessUniversalCheckoutDidTokenizePaymentMethod?(paymentMethodTokenData) { decision in
                        continuation.resume(returning: decision)
                    }
            } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                Primer.shared.delegate?.primerDidTokenizePaymentMethod?(paymentMethodTokenData) { decision in
                    continuation.resume(returning: decision)
                }
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

    @MainActor
    static func primerDidResumeWith(_ resumeToken: String) async -> PrimerResumeDecisionProtocol {
        await withCheckedContinuation { continuation in
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidResumeWith?(resumeToken) { decision in
                    continuation.resume(returning: decision)
                }
            } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                Primer.shared.delegate?.primerDidResumeWith?(resumeToken) { decision in
                    continuation.resume(returning: decision)
                }
            }
        }
    }

    static func primerWillCreatePaymentWithData(
        _ data: PrimerCheckoutPaymentMethodData,
        decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void
    ) {
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

    @MainActor
    static func primerWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData) async -> PrimerPaymentCreationDecision {
        await withCheckedContinuation { continuation in
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                if let primerHeadlessUniversalCheckoutWillCreatePaymentWithData = PrimerHeadlessUniversalCheckout.current.delegate?
                    .primerHeadlessUniversalCheckoutWillCreatePaymentWithData {
                    primerHeadlessUniversalCheckoutWillCreatePaymentWithData(data) { decision in
                        continuation.resume(returning: decision)
                    }
                } else {
                    continuation.resume(returning: .continuePaymentCreation())
                }
            } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                if let primerWillCreatePaymentWithData = Primer.shared.delegate?.primerWillCreatePaymentWithData {
                    primerWillCreatePaymentWithData(data) { decision in
                        continuation.resume(returning: decision)
                    }
                } else {
                    continuation.resume(returning: .continuePaymentCreation())
                }
            }
        }
    }

    static func primerDidDismiss(paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory]) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                Primer.shared.delegate?.primerDidDismiss?()
            } else if paymentMethodManagerCategories.contains(.nativeUI) {
                PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniveraslCheckoutUIDidDismissPaymentMethod?()
                PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidDismissPaymentMethod?()
            }
        }
    }

    @MainActor
    static func primerDidDismiss(paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory]) async {
        if PrimerInternal.shared.sdkIntegrationType == .dropIn {
            Primer.shared.delegate?.primerDidDismiss?()
        } else if paymentMethodManagerCategories.contains(.nativeUI) {
            PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniveraslCheckoutUIDidDismissPaymentMethod?()
            PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidDismissPaymentMethod?()
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

    @MainActor
    static func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) async {
        if PrimerInternal.shared.sdkIntegrationType == .headless {
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(data)

            if let timingEventId = PrimerHeadlessUniversalCheckout.current.timingEventId,
               PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData != nil {
                let timingEndEvent = Analytics.Event.timer(
                    momentType: .start,
                    id: timingEventId
                )

                Task { try await Analytics.Service.record(events: [timingEndEvent]) }
            }

            PrimerUIManager.dismissPrimerUI(animated: true)

        } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
            Primer.shared.delegate?.primerDidCompleteCheckoutWithData(data)
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

    @MainActor
    static func primerDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) async {
        if PrimerInternal.shared.sdkIntegrationType == .headless {
            let delegate = PrimerHeadlessUniversalCheckout.current.delegate
            delegate?.primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo?(additionalInfo)

        } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
            Primer.shared.delegate?.primerDidEnterResumePendingWithPaymentAdditionalInfo?(additionalInfo)
        }
    }

    static func primerDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo?(additionalInfo)
            }
        }
    }

    @MainActor
    static func primerDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo) async {
        if PrimerInternal.shared.sdkIntegrationType == .headless {
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo?(additionalInfo)
        }
    }

    static func primerDidFailWithError(
        _ error: any PrimerErrorProtocol,
        data: PrimerCheckoutData?,
        decisionHandler: @escaping ((PrimerErrorDecision) -> Void)
    ) {
        DispatchQueue.main.async {
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

    @MainActor
    static func primerDidFailWithError(_ error: any PrimerErrorProtocol, data: PrimerCheckoutData?) async -> PrimerErrorDecision {
        let exposedError: Error = error.exposedError

        if PrimerInternal.shared.sdkIntegrationType == .headless {
            if let timingEventId = PrimerHeadlessUniversalCheckout.current.timingEventId,
               PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData != nil {
                let timingEndEvent = Analytics.Event.timer(
                    momentType: .end,
                    id: timingEventId
                )

                try? await Analytics.Service.record(events: [timingEndEvent])
                try? await Analytics.Service.flush()
            }

            PrimerUIManager.dismissPrimerUI(animated: true)

            guard let primerHeadlessUniversalCheckoutDidFail = PrimerHeadlessUniversalCheckout.current.delegate?
                .primerHeadlessUniversalCheckoutDidFail else {
                logger.warn(message: "Delegate function 'primerHeadlessUniversalCheckoutDidFail' hasn't been implemented.")
                return .fail(withErrorMessage: nil)
            }

            primerHeadlessUniversalCheckoutDidFail(exposedError, data)
            return .fail(withErrorMessage: nil)

        } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
            guard let primerDidFailWithError = Primer.shared.delegate?.primerDidFailWithError else {
                let message = """
                Delegate function 'primerDidFailWithError' hasn't been implemented.\
                No custom error message will be displayed on the error screen.
                """
                logger.warn(message: message)
                return .fail(withErrorMessage: nil)
            }

            return await withCheckedContinuation { continuation in
                primerDidFailWithError(exposedError, data) { errorDecision in
                    switch errorDecision.type {
                    case .fail(let message):
                        continuation.resume(returning: .fail(withErrorMessage: message))
                    }
                }
            }
        } else {
            preconditionFailure()
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

    @MainActor
    static func raisePrimerDidFailWithError(_ primerError: PrimerError, data: PrimerCheckoutData?) async -> String? {
        await withCheckedContinuation { continuation in
            PrimerDelegateProxy.primerDidFailWithError(primerError, data: data) { errorDecision in
                switch errorDecision.type {
                case .fail(let message):
                    continuation.resume(returning: message)
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

    @MainActor
    static func primerClientSessionWillUpdate() async {
        if PrimerInternal.shared.sdkIntegrationType == .headless {
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutWillUpdateClientSession?()
        } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
            Primer.shared.delegate?.primerClientSessionWillUpdate?()
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

    @MainActor
    static func primerClientSessionDidUpdate(_ clientSession: PrimerClientSession) async {
        if PrimerInternal.shared.sdkIntegrationType == .headless {
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidUpdateClientSession?(clientSession)
        } else if PrimerInternal.shared.sdkIntegrationType == .dropIn {
            Primer.shared.delegate?.primerClientSessionDidUpdate?(clientSession)
        }
    }

    static func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods?(paymentMethods)
            }
        }
    }

    @MainActor
    static func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethods: [PrimerHeadlessUniversalCheckout
            .PaymentMethod]) async {
        if PrimerInternal.shared.sdkIntegrationType == .headless {
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods?(paymentMethods)
        }
    }

    static func primerHeadlessUniversalCheckoutUIDidStartPreparation(for paymentMethodType: String) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidStartPreparation?(for: paymentMethodType)
            }
        }
    }

    @MainActor
    static func primerHeadlessUniversalCheckoutUIDidStartPreparation(for paymentMethodType: String) async {
        if PrimerInternal.shared.sdkIntegrationType == .headless {
            PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidStartPreparation?(for: paymentMethodType)
        }
    }

    static func primerHeadlessUniversalCheckoutDidStartTokenization(for paymentMethodType: String) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidStartTokenization?(for: paymentMethodType)
            }
        }
    }

    @MainActor
    static func primerHeadlessUniversalCheckoutDidStartTokenization(for paymentMethodType: String) async {
        if PrimerInternal.shared.sdkIntegrationType == .headless {
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidStartTokenization?(for: paymentMethodType)
        }
    }

    static func primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for paymentMethodType: String) {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod?(for: paymentMethodType)
            }
        }
    }

    @MainActor
    static func primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for paymentMethodType: String) async {
        DispatchQueue.main.async {
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod?(for: paymentMethodType)
            }
        }
    }
}
