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
    var availableCategories: [KlarnaPaymentCategory] = []
    var isFinalizationRequired: Bool = false
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
    func setNeededDelegates() {}
    
    /// Reset some variables if needed
    func resetVariables() {}

    /// Validates the tokenization component, handling any errors that occur during the process.
    func validate() {
        do {
            try tokenizationComponent.validate()
        } catch {
            if let err = error as? PrimerError {
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
        
        switch collectableData {
        case .collectUserDetails(let details):
            
            do {
                try StripeAchUserDetails.validate(userDetails: stripeach)
                
            } catch StripeAchUserDetailsError.validationErrors(let errors) {
                var validationErrors: [PrimerValidationError] = []
                for error in errors {
                    
                    validationErrors.append(
                        PrimerValidationError.invalidValue(
                            field: error.fieldValue,
                            userInfo: .errorUserInfoDictionary(),
                            diagnosticsId: UUID().uuidString)
                    )
                }
                validationDelegate?.didUpdate(validationStatus: .invalid(errors: validationErrors), for: collectableData)
            } catch {
                print("An unexpected error occurred")
            }
            
            validationDelegate?.didUpdate(validationStatus: .valid, for: collectableData)
        }
    }

    // Submit the
    public func submit() {
        trackSubmit()
    }

    /// Initiates the creation of a Klarna payment session.
    public func start() {
        validate()
        trackStart()
    }
}

// TODO: - Some API calls that will be made before starting the Tokenization and maybe after
extension StripeAchHeadlessComponent {
    
}

// MARK: - PrimerStripeCollectorViewControllerDelegate
extension StripeAchHeadlessComponent { // PrimerStripeCollectorViewControllerDelegate
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
            errorDelegate?.didReceiveError(error: primerError)
        }
    }
}

// MARK: - Helper methods
extension StripeAchHeadlessComponent {
    
}

// MARK: Recording Analytics
extension StripeAchHeadlessComponent: PrimerHeadlessAnalyticsRecordable {
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
