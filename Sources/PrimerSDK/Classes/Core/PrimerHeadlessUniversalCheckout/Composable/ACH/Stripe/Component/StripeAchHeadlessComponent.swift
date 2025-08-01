//
//  StripeAchHeadlessComponent.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

final class StripeAchHeadlessComponent {
    // MARK: - Tokenization
    var tokenizationViewModel: StripeAchTokenizationViewModel
    var clientSessionService: ACHClientSessionService

    /// Global settings for the payment process, injected as a dependency.
    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
    var inputUserDetails: ACHUserDetails = .emptyUserDetails()
    var clientSessionUserDetails: ACHUserDetails = .emptyUserDetails()
    // MARK: - Delegates
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public internal(set) var nextDataStep: ACHUserDetailsStep = .notInitialized
    // MARK: - Init
    init(tokenizationViewModel: StripeAchTokenizationViewModel) {
        self.tokenizationViewModel = tokenizationViewModel
        self.clientSessionService = ACHClientSessionService()
    }

    func setDelegate() {}

    /// Reset some variables if needed
    func resetClientSessionDetails() {
        inputUserDetails = .emptyUserDetails()
        clientSessionUserDetails = .emptyUserDetails()
    }

    /// Validates the tokenization component, handling any errors that occur during the process.
    func validate() {
        if PrimerInternal.shared.sdkIntegrationType == .headless {
            do {
                try tokenizationViewModel.validate()
            } catch {
                if let err = error as? PrimerError {
                    errorDelegate?.didReceiveError(error: handled(primerError: err))
                }
            }
        }
    }
}

// MARK: - PrimerHeadlessAchComponent delegates
extension StripeAchHeadlessComponent: StripeAchUserDetailsComponent {
    public func updateCollectedData(collectableData: ACHUserDetailsCollectableData) {
        trackCollectableData()
        validationDelegate?.didUpdate(validationStatus: .validating, for: collectableData)
        if collectableData.isValid {
            inputUserDetails.update(with: collectableData)
            validationDelegate?.didUpdate(validationStatus: .valid, for: collectableData)
        } else {
            let error = handled(error: collectableData.invalidFieldError)
            let validationError = PrimerValidationError.invalidUserDetails(field: error.fieldValueDescription)
            validationDelegate?.didUpdate(validationStatus: .invalid(errors: [validationError]), for: collectableData)
        }
    }

    /// Get client session user details.
    public func start() {
        validate()
        trackStart()
        setClientSessionActions()
        getClientSessionUserDetails()
    }
    /// Submit the user details and patch the client if needed
    public func submit() {
        trackSubmit()
        patchClientSessionIfNeeded()
    }
}

// MARK: Recording Analytics
extension StripeAchHeadlessComponent: PrimerHeadlessAnalyticsRecordable {
    func trackStart() {
        recordEvent(
            type: .sdkEvent,
            name: ACHAnalyticsEvents.stripe.startMethod,
            params: [:]
        )
    }
    func trackSubmit() {
        recordEvent(
            type: .sdkEvent,
            name: ACHAnalyticsEvents.stripe.submitMethod,
            params: [:]
        )
    }
    func trackCollectableData() {
        recordEvent(
            type: .sdkEvent,
            name: ACHAnalyticsEvents.stripe.updateCollectedData,
            params: [:]
        )
    }
}
