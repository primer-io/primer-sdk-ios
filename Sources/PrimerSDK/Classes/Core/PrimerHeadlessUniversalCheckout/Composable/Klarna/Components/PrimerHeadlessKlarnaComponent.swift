//
//  PrimerHeadlessKlarnaComponent.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
import Foundation
import UIKit
import PrimerKlarnaSDK

final class PrimerHeadlessKlarnaComponent {
    // MARK: - Tokenization
    var tokenizationComponent: KlarnaTokenizationComponentProtocol
    /// Global settings for the payment process, injected as a dependency.
    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
    var availableCategories: [KlarnaPaymentCategory] = []
    var isFinalizationRequired: Bool = false
    // MARK: - Provider
    var klarnaProvider: PrimerKlarnaProviding?
    // MARK: - Delegates
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public internal(set) var nextDataStep: KlarnaStep = .notLoaded

    // MARK: - Init
    init(tokenizationComponent: KlarnaTokenizationComponentProtocol) {
        self.tokenizationComponent = tokenizationComponent
    }

    func setPaymentSessionDelegates() {
        setAuthorizationDelegate()
        setFinalizationDelegate()
        setPaymentViewDelegate()
    }

    /// Configures the Klarna provider and view handling component with necessary information for payment processing.
    func setProvider(with clientToken: String, paymentCategory: String) {
        let urlScheme = (try? settings.paymentMethodOptions.validUrlForUrlScheme())?.absoluteString
        let provider: PrimerKlarnaProviding = PrimerKlarnaProvider(clientToken: clientToken,
                                                                   paymentCategory: paymentCategory,
                                                                   urlScheme: urlScheme)
        klarnaProvider = provider
    }

    /// Validates the tokenization component, handling any errors that occur during the process.
    func validate() -> Bool {
        do {
            try tokenizationComponent.validate()
            return true
        } catch {
            if let err = error as? PrimerError {
                handleReceivedError(error: err)
            }
            return false
        }
    }

    func resetKlarnaSessionVariables() {
        isFinalizationRequired = false
        availableCategories = []
    }
}

// MARK: - PrimerHeadlessMainComponent
extension PrimerHeadlessKlarnaComponent: KlarnaComponent {
    public func updateCollectedData(collectableData: KlarnaCollectableData) {
        trackCollectableData()
        validateData(for: collectableData)
        switch collectableData {
        case .paymentCategory:
            createPaymentView()
            initPaymentView()
        case .finalizePayment:
            finalizePayment()
        }
    }

    func validateData(for data: KlarnaCollectableData) {
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        switch data {
        case .paymentCategory(_: let category, clientToken: let clientToken):
            guard let clientToken = clientToken else {
                let error = handled(error: KlarnaHelpers.getInvalidTokenError())
                validationDelegate?.didUpdate(validationStatus: .error(error: error), for: data)
                return
            }
            guard !availableCategories.isEmpty else {
                let error = handled(error: PrimerValidationError.sessionNotCreated())
                validationDelegate?.didUpdate(validationStatus: .invalid(errors: [error]), for: data)
                return
            }
            guard availableCategories.contains(where: { $0 == category }) else {
                let error = handled(error: PrimerValidationError.invalidPaymentCategory())
                validationDelegate?.didUpdate(validationStatus: .invalid(errors: [error]), for: data)
                return
            }
            setProvider(with: clientToken, paymentCategory: category.id)
            setPaymentSessionDelegates()
            validationDelegate?.didUpdate(validationStatus: .valid, for: data)
        case .finalizePayment:
            guard isFinalizationRequired else {
                let error = handled(error: PrimerValidationError.paymentAlreadyFinalized())
                validationDelegate?.didUpdate(validationStatus: .invalid(errors: [error]), for: data)
                return
            }
        }
    }

    public func submit() {
        trackSubmit()
        authorizeSession()
    }

    /// Initiates the creation of a Klarna payment session.
    public func start() {
        if validate() {
            trackStart()
            startSession()
        }
    }
}

// MARK: - Finalize payment session and Tokenization process
extension PrimerHeadlessKlarnaComponent {
    /**
     * Finalizes the payment session with specific authorization and tokenization processes.
     *
     * - Parameters:
     *   - token: A `String` representing the authorization token used for payment session authorization.
     *            This token is necessary for both the initial authorization request and the tokenization process that follows.
     *   - fromAuthorization: A `Bool` indicating whether the current operation is coming from Authorization or Finalization flow.
     *
     * This method first attempts to finalize the payment session using the provided `token`.
     * Upon successful finalization, it proceeds to tokenize the customer token received in response.
     */
    func finalizeSession(token: String, fromAuthorization: Bool) {
        firstly {
            tokenizationComponent.authorizePaymentSession(authorizationToken: token)
        }
        .then { customerToken in
            self.tokenizationComponent.tokenizeHeadless(customerToken: customerToken, offSessionAuthorizationId: token)
        }
        .done { checkoutData in
            if fromAuthorization {
                let step = KlarnaStep.paymentSessionAuthorized(authToken: token, checkoutData: checkoutData)
                self.stepDelegate?.didReceiveStep(step: step)
            } else {
                // Finalization
                let step = KlarnaStep.paymentSessionFinalized(authToken: token, checkoutData: checkoutData)
                self.stepDelegate?.didReceiveStep(step: step)
            }
            PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
            self.resetKlarnaSessionVariables()
        }
        .catch { error in
            self.createSessionError(.sessionAuthorizationFailed(error: error))
            self.resetKlarnaSessionVariables()
        }
    }
}

// MARK: - PrimerKlarnaProviderErrorDelegate
extension PrimerHeadlessKlarnaComponent: PrimerKlarnaProviderErrorDelegate {
    /// Handles errors from the Klarna SDK, forwarding them to the configured error delegate.
    public func primerKlarnaWrapperFailed(with error: PrimerKlarnaSDK.PrimerKlarnaError) {
        let primerError = PrimerError.klarnaError(
            message: error.errorDescription,
            diagnosticsId: error.diagnosticsId
        )
        handleReceivedError(error: primerError)
    }
}

// MARK: Recording Analytics
extension PrimerHeadlessKlarnaComponent: PrimerHeadlessAnalyticsRecordable {
    func trackStart() {
        recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.createSessionMethod,
            params: [:]
        )
    }

    func trackSubmit() {
        recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.authorizeSessionMethod,
            params: [:]
        )
    }

    func trackCollectableData() {
        recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.updateCollectedData,
            params: [:]
        )
    }
}
#endif
