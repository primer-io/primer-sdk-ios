//
//  StripeAchHeadlessComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import UIKit

class StripeAchHeadlessComponent {
    // MARK: - Tokenization
    var tokenizationComponent: StripeAchTokenizationComponentProtocol
    
    /// Global settings for the payment process, injected as a dependency.
    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
    var inputUserDetails: StripeAchUserDetails = .emptyUserDetails()
    var clientSessionUserDetails: StripeAchUserDetails = .emptyUserDetails()
    
    // MARK: - Delegates
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public internal(set) var nextDataStep: StripeAchStep = .notInitialized
    
    // MARK: - Init
    init(tokenizationComponent: StripeAchTokenizationComponentProtocol) {
        self.tokenizationComponent = tokenizationComponent
    }
    
    /// Delegation
    func setDelegate() {}
    
    /// Reset some variables if needed
    func resetVariables() {
        inputUserDetails = .emptyUserDetails()
        clientSessionUserDetails = .emptyUserDetails()
    }
    
    /// Validates the tokenization component, handling any errors that occur during the process.
    func validate() {
        do {
            try tokenizationComponent.validate()
        } catch {
            if let err = error as? PrimerError {
                ErrorHandler.handle(error: error)
                errorDelegate?.didReceiveError(error: err)
            }
        }
    }
}

// MARK: - PrimerHeadlessMainComponent delegates
extension StripeAchHeadlessComponent: StripeAchUserDetailsComponent {
    public func updateCollectedData(collectableData: StripeAchCollectableData) {
        trackCollectableData()
        validationDelegate?.didUpdate(validationStatus: .validating, for: collectableData)
        
        if collectableData.isValid {
            inputUserDetails.update(with: collectableData)
            validationDelegate?.didUpdate(validationStatus: .valid, for: collectableData)
        } else {
            let error = collectableData.invalidFieldError
            ErrorHandler.handle(error: error)
            let validationError = PrimerValidationError.invalidValue(
                field: error.fieldValue,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            
            validationDelegate?.didUpdate(validationStatus: .invalid(errors: [validationError]), for: collectableData)
        }
    }

    /// Get client session user details.
    public func start() {
        validate()
        trackStart()
        getClientSessionUserDetails()
    }
    
    /// Submit the user details and patch the client if needed
    public func submit() {
        trackSubmit()
        patchClientSessionIfNeeded()
    }
}

// MARK: - PrimerStripeCollectorViewControllerDelegate
extension StripeAchHeadlessComponent: PrimerStripeCollectorViewControllerDelegate {
    /// Handles statuses from the PrimerStripeSDK, forwarding them to the next steps.
    public func primerStripeCollected(_ stripeStatus: PrimerStripeStatus) {
        switch stripeStatus {
        case .succeeded(let paymentId):
            // TODO: handle success case
            break
        case .canceled:
            // TODO: handle canceled case
            break
        case .failed(let error):
            // TODO: handle error case
            let primerError = PrimerError.stripeWrapperError(
                message: error.errorDescription,
                userInfo: error.userInfo,
                diagnosticsId: error.diagnosticsId
            )
            ErrorHandler.handle(error: primerError)
            errorDelegate?.didReceiveError(error: primerError)
        }
    }
}

// MARK: Recording Analytics
extension StripeAchHeadlessComponent: PrimerHeadlessAnalyticsRecordable {
    func trackStart() {
        recordEvent(
            type: .sdkEvent,
            name: StripeAnalyticsEvents.startMethod,
            params: [:]
        )
    }
    
    func trackSubmit() {
        recordEvent(
            type: .sdkEvent,
            name: StripeAnalyticsEvents.submitMethod,
            params: [:]
        )
    }
    
    func trackCollectableData() {
        recordEvent(
            type: .sdkEvent,
            name: StripeAnalyticsEvents.updateCollectedData,
            params: [:]
        )
    }
}
