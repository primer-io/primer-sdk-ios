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
 */
enum KlarnaSessionError {
    case missingConfiguration
    case invalidClientToken
    case sessionCreationFailed(error: Error)
    case sessionAuthorizationFailed(error: Error)
    case klarnaAuthorizationFailed
    case klarnaFinalizationFailed
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
        firstly {
            tokenizationComponent.createPaymentSession()
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
extension PrimerHeadlessKlarnaComponent {
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
                userInfo: KlarnaHelpers.getErrorUserInfo(),
                diagnosticsId: UUID().uuidString
            )
        case .invalidClientToken:
            primerError = PrimerError.invalidClientToken(
                userInfo: KlarnaHelpers.getErrorUserInfo(),
                diagnosticsId: UUID().uuidString
            )
        case .sessionCreationFailed(let error):
            primerError = PrimerError.failedToCreateSession(
                error: error,
                userInfo: KlarnaHelpers.getErrorUserInfo(),
                diagnosticsId: UUID().uuidString
            )
        case .sessionAuthorizationFailed(error: let error):
            primerError = PrimerError.paymentFailed(
                paymentMethodType: "KLARNA",
                description: error.localizedDescription,
                userInfo: KlarnaHelpers.getErrorUserInfo(),
                diagnosticsId: UUID().uuidString
            )
        case .klarnaAuthorizationFailed:
            primerError = PrimerError.klarnaWrapperError(
                message: "PrimerKlarnaWrapperAuthorization failed",
                userInfo: KlarnaHelpers.getErrorUserInfo(),
                diagnosticsId: UUID().uuidString
            )
        case .klarnaFinalizationFailed:
            primerError = PrimerError.klarnaWrapperError(
                message: "PrimerKlarnaWrapperFinalization failed",
                userInfo: KlarnaHelpers.getErrorUserInfo(),
                diagnosticsId: UUID().uuidString
            )
        }
        errorDelegate?.didReceiveError(error: primerError)
    }
}
#endif
