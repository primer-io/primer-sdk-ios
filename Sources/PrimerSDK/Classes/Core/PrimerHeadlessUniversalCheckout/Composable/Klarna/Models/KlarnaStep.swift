//
//  KlarnaStep.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 21.02.2024.
//

import Foundation

/**
 * Represents the possible outcomes of a Klarna payment session creation process.
 * Enumerates the possible states and outcomes related to the authorization of a Klarna payment session.
 * This enum is used to communicate the result of attempting to create, authorize and finalize a payment session with Klarna.
 * It conforms to `PrimerHeadlessStep`.
 *
 * Cases:
 * - paymentSessionCreated: Indicates a successful creation of a payment session. It caries:
 *     - `clientToken` string, which is used for further API interactions.
 *     - `paymentCategories` of type `KlarnaPaymentCategory`, representing the available payment options for the user.
 *
 * - paymentSessionAuthorized: Indicates that the payment session has been successfully authorized. It carries an `authToken` string for subsequent operations that require authorization.
 * - paymentSessionAuthorizationFailed: Represents a failure in the authorization process.
 * - paymentSessionFinalizationRequired: Signals that the payment session requires finalization steps to be completed by the user or the system.
 *
 * - paymentSessionReauthorized: Similar to `paymentSessionAuthorized`.
 * - paymentSessionReauthorizationFailed: Indicates a failure in the reauthorization process of an existing payment session.
 *
 * - paymentSessionFinalized: Indicates a successful finalization of a payment session. It caries:
 *     - `authToken` string, which is used for further API interactions.
 * - paymentSessionFinalizationFailed: Represents a failure in finalizing the process.
 *
 * - `viewInitialized`: Indicates that the Klarna view has been initialized. This is the first step in the Klarna view handling process.
 * - `viewResized(height: CGFloat)`: Represents a change in the view's height, which may occur when the Klarna view adjusts to display different content. The `height` parameter specifies the new height of the view.
 * - `viewLoaded`: Signifies that the Klarna view has finished loading its initial content and is ready for interaction.
 * - `reviewLoaded`: Indicates that the reviewed information has been loaded into the Klarna view.
 */
public enum KlarnaStep: PrimerHeadlessStep {
    /// Session creation
    case paymentSessionCreated(clientToken: String, paymentCategories: [KlarnaPaymentCategory])
    
    /// Session authorization
    case paymentSessionAuthorized(authToken: String, checkoutData: PrimerCheckoutData)
    case paymentSessionAuthorizationFailed(error: Error?)
    case paymentSessionFinalizationRequired
    
    /// Session finalization
    case paymentSessionFinalized(authToken: String, checkoutData: PrimerCheckoutData)
    case paymentSessionFinalizationFailed(error: Error?)
    
    /// Payment view handling
    case viewInitialized
    case viewResized(height: CGFloat)
    case viewLoaded
    case reviewLoaded
    case isLoading
}
