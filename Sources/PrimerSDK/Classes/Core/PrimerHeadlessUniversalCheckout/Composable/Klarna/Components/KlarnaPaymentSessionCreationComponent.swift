//
//  KlarnaPaymentSessionCreationComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.01.2024.
//

import Foundation

/**
 * Represents the possible outcomes of a Klarna payment session creation process.
 *
 * This enum is used to communicate the result of attempting to create a payment session with Klarna.
 * It conforms to `PrimerHeadlessStep`.
 *
 * Cases:
 * - paymentSessionCreated: Indicates a successful creation of a payment session. It caries:
 *     - `clientToken` string, which is used for further API interactions.
 *     - `paymentCategories` of type `KlarnaPaymentCategory`, representing the available payment options for the user.
 */
public enum KlarnaPaymentSessionCreation: PrimerHeadlessStep {
    case paymentSessionCreated(clientToken: String, paymentCategories: [KlarnaPaymentCategory])
}

/**
 * Defines the specific errors that can be encountered during the Klarna payment session creation process.
 * This enum categorizes errors specific to the Klarna payment session creation component.
 *
 * - Cases:
 *  - missingConfiguration: Indicates that essential configuration details are missing, which are required to initiate the payment session creation process.
 *  - invalidClientToken: Signifies that the client token provided for the session creation is invalid or malformed, preventing further API interactions.
 *  - createPaymentSessionFailed: Represents a failure in the payment session creation process, encapsulating the underlying `Error` that led to the failure.
 */
enum KlarnaPaymentSessionCreationComponentError {
    case missingConfiguration
    case invalidClientToken
    case createPaymentSessionFailed(error: Error)
}

public class KlarnaPaymentSessionCreationComponent: PrimerHeadlessAnalyticsRecordable {
    
    // MARK: - Tokenization
    private var tokenizationComponent: KlarnaTokenizationComponentProtocol
    
    // MARK: - Properties
    private(set) var customerAccountInfo: KlarnaCustomerAccountInfo?
    
    // MARK: - Delegates
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    
    // MARK: - Init
    init(tokenizationComponent: KlarnaTokenizationComponentProtocol) {
        self.tokenizationComponent = tokenizationComponent
    }
}

// MARK: - Start
public extension KlarnaPaymentSessionCreationComponent {
    
    /**
     * Initiates the process of creating a payment session.
     * This method kicks off the payment session creation process by first recording the creation event for tracking or analytical purposes.
        - Success: it handles the creation of a payment session step
        - Failure: It handles the creation of a payment session error
     */
    func start() {
        recordCreationEvent()
        
        firstly {
            tokenizationComponent.createPaymentSession()
        }
        .done { paymentSession in
            self.createSessionStep(paymentSession)
        }
        .catch { error in
            self.createSessionError(.createPaymentSessionFailed(error: error))
        }
    }
}

// MARK: - Private
private extension KlarnaPaymentSessionCreationComponent {
    
    /**
     * Processes and communicates the successful creation of a payment session.
     * This method takes the response from a successful payment session creation and extracts necessary details to form a `KlarnaPaymentSessionCreation` step.
     * It encapsulates the client token and payment categories from the response into this step.
     * Then notifies the `stepDelegate` of this successful step
     */
    func createSessionStep(_ response: Response.Body.Klarna.PaymentSession) {
        let step = KlarnaPaymentSessionCreation.paymentSessionCreated(
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
     * This method utilizes a switch statement to differentiate between various types of `KlarnaPaymentSessionCreationComponentError`, and constructs a specific `PrimerError`.
     * Then notifies the `errorDelegate` with the specific `PrimerError`.
     */
    func createSessionError(_ error: KlarnaPaymentSessionCreationComponentError) {
        var primerError: PrimerError
        
        let userInfo: [String: String] = [
            "file": #file,
            "class": "\(Self.self)",
            "function": #function,
            "line": "\(#line)"
        ]
        
        switch error {
        case .missingConfiguration:
            primerError = PrimerError.missingPrimerConfiguration(
                userInfo: userInfo,
                diagnosticsId: UUID().uuidString
            )
            
        case .invalidClientToken:
            primerError = PrimerError.invalidClientToken(
                userInfo: userInfo,
                diagnosticsId: UUID().uuidString
            )
            
        case .createPaymentSessionFailed(let error):
            primerError = PrimerError.failedToCreateSession(
                error: error,
                userInfo: userInfo,
                diagnosticsId: UUID().uuidString
            )
        }
        
        errorDelegate?.didReceiveError(error: primerError)
    }
}

// MARK: - Helpers
private extension KlarnaPaymentSessionCreationComponent {
    private func recordCreationEvent() {
        recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.CREATE_SESSION_START_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE,
            ]
        )
    }
}
