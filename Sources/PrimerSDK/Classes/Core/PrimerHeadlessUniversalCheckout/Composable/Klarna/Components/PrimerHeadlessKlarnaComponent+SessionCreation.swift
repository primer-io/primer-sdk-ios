//
//  KlarnaComponent+Creation.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 16.02.2024.
//

#if canImport(PrimerKlarnaSDK)
import Foundation
import UIKit

/**
 * Defines the specific errors that can be encountered during the Klarna payment session creation process.
 * This enum categorizes errors specific to the Klarna payment session creation component.
 *
 * - Cases:
 *  - missingConfiguration: Indicates that essential configuration details are missing, which are required to initiate the payment session creation process.
 *  - invalidClientToken: Signifies that the client token provided for the session creation is invalid or malformed, preventing further API interactions.
 *  - createPaymentSessionFailed: Represents a failure in the payment session creation process, encapsulating the underlying `Error` that led to the failure.
 *  - sessionAuthorizationFailed: Indicates a failure during the authorization phase of the payment, encapsulating the underlying `Error` that caused the authorization to fail.
 *  - klarnaAuthorizationFailed: Represents a failure specific to Klarna's authorization process, which is a step where Klarna verifies and authorizes the payment details provided by the user.
 *  - klarnaFinalizationFailed: Indicates that the finalization step of the Klarna payment process has failed.
 *  - klarnaUserNotApproved:  Indicates that the user has not been approved for the Klarna payment method, due to various reasons such as "Invalid Card Information" or "User Cancels The Authorization" or "Missing or Invalid Fields in Authorize Data". For more information, https://docs.klarna.com/payments/mobile-payments/before-you-start/flows-and-error-handling
 */
enum KlarnaSessionError {
    case missingConfiguration
    case invalidClientToken
    case sessionCreationFailed(error: Error)
    case sessionAuthorizationFailed(error: Error)
    case klarnaAuthorizationFailed
    case klarnaFinalizationFailed
    case klarnaUserNotApproved
}

// MARK: - Start

extension PrimerHeadlessKlarnaComponent {
    /**
     * Initiates the process of creating a payment session.
     * This method kicks off the payment session creation process by first recording the creation event for tracking or analytical purposes.
     * - Success: it handles the creation of a payment session step
     * - Failure: It handles the creation of a payment session error
     */
    func startSession() {
        // TODO: FINAL_MIGRATION
        firstly {
            handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: PrimerPaymentMethodType.klarna.rawValue))
        }
        .then { () -> Promise<Response.Body.Klarna.PaymentSession> in
            self.tokenizationComponent.createPaymentSession()
        }
        .done { paymentSession in
            self.createSessionStep(paymentSession)
        }
        .catch { error in
            self.createSessionError(.sessionCreationFailed(error: error))
        }
    }
}

// MARK: - Private

extension PrimerHeadlessKlarnaComponent: LogReporter {
    /**
     * Processes and communicates the successful creation of a payment session.
     * This method takes the response from a successful payment session creation and extracts necessary details to form a `KlarnaPaymentSessionCreation` step.
     * It encapsulates the client token and payment categories from the response into this step.
     * Then notifies the `stepDelegate` of this successful step
     */
    func createSessionStep(_ response: Response.Body.Klarna.PaymentSession) {
        availableCategories = response.categories.map { KlarnaPaymentCategory(response: $0) }
        let step = KlarnaStep.paymentSessionCreated(
            clientToken: response.clientToken,
            paymentCategories: response.categories.map { KlarnaPaymentCategory(response: $0) }
        )
        stepDelegate?.didReceiveStep(step: step)
    }

    /**
     * Handles errors encountered during the payment session creation process.
     * This method processes a specific `KlarnaPaymentSessionCreationComponentError` and converts it into a more generalized `PrimerError`.
     *
     * - Parameter error: A `KlarnaPaymentSessionCreationComponentError` representing the specific error encountered during the payment session creation process.
     *
     * This method utilizes a switch statement to differentiate between various types of `KlarnaSessionError`, and constructs a specific `PrimerError`.
     * Then notifies the `errorDelegate` with the specific `PrimerError`.
     */
    func createSessionError(_ error: KlarnaSessionError) {
        var primerError: PrimerError
        switch error {
        case .missingConfiguration:
            primerError = PrimerError.missingPrimerConfiguration(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
        case .invalidClientToken:
            primerError = PrimerError.invalidClientToken(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
        case .sessionCreationFailed(let error):
            primerError = PrimerError.failedToCreateSession(
                error: error,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
        case .sessionAuthorizationFailed(error: let error):
            primerError = PrimerError.failedToCreatePayment(
                paymentMethodType: "KLARNA",
                description: error.localizedDescription,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
        case .klarnaAuthorizationFailed:
            primerError = PrimerError.klarnaError(
                message: "PrimerKlarnaWrapperAuthorization failed",
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
        case .klarnaFinalizationFailed:
            primerError = PrimerError.klarnaError(
                message: "PrimerKlarnaWrapperFinalization failed",
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
        case .klarnaUserNotApproved:
            primerError = PrimerError.klarnaUserNotApproved(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
        }
        handleReceivedError(error: primerError)
    }

    func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void> {
        return Promise { seal in
            if PrimerInternal.shared.intent == .vault {
                seal.fulfill()
            } else {
                let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
                let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)

                var decisionHandlerHasBeenCalled = false

                PrimerDelegateProxy.primerWillCreatePaymentWithData(
                    checkoutPaymentMethodData,
                    decisionHandler: { paymentCreationDecision in
                        decisionHandlerHasBeenCalled = true
                        switch paymentCreationDecision.type {
                        case .abort(let errorMessage):
                            let error = PrimerError.merchantError(message: errorMessage ?? "",
                                                                  userInfo: .errorUserInfoDictionary(),
                                                                  diagnosticsId: UUID().uuidString)
                            seal.reject(error)
                        case .continue:
                            seal.fulfill()
                        }
                    }
                )

                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    if !decisionHandlerHasBeenCalled {
                        let message =
                            """
                            The 'decisionHandler' of 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData' hasn't been called. \
                            Make sure you call the decision handler otherwise the SDK will hang.
                            """
                        self?.logger.warn(message: message)
                    }
                }
            }
        }
    }

    func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) async throws {
        if PrimerInternal.shared.intent == .vault {
            return
        }

        let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
        let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)

        var decisionHandlerHasBeenCalled = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if !decisionHandlerHasBeenCalled {
                let message =
                    """
                    The 'decisionHandler' of 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData' hasn't been called. \
                    Make sure you call the decision handler otherwise the SDK will hang.
                    """
                self?.logger.warn(message: message)
            }
        }

        let paymentCreationDecision = try await PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData)
        decisionHandlerHasBeenCalled = true

        switch paymentCreationDecision.type {
        case .abort(let errorMessage):
            let error = PrimerError.merchantError(message: errorMessage ?? "",
                                                  userInfo: .errorUserInfoDictionary(),
                                                  diagnosticsId: UUID().uuidString)
            throw error
            
        case .continue:
            return
        }
    }
}
#endif
