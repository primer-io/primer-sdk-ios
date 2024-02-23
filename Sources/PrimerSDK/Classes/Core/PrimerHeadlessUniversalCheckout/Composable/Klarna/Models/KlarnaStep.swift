//
//  KlarnaStep.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 21.02.2024.
//

import Foundation

/**
 * This enum is used to communicate the result of attempting to create, authorize and finalize a payment session with Klarna also handling the PaymentView.
 * It conforms to `PrimerHeadlessStep`.
 *
 * Cases:
 * - `paymentSessionCreated`: Indicates a successful creation of a payment session. It caries:
 *     - `clientToken` string,  which is used for validation purposes.
 *     - `paymentCategories` of type `KlarnaPaymentCategory`, representing the available payment options for the user.
 *
 * - `paymentSessionAuthorized`: Indicates that the payment session has been successfully authorized.It carries:
 *     - `authToken` string for subsequent operations that require authorization.
 *     - `checkoutData` for showing the checkout results, after the merchant finishes the payment.
 * - `paymentSessionFinalizationRequired`: Signals that the payment session requires finalization steps to be completed by the user or the system.
 *
 * - `paymentSessionFinalized`: Indicates a successful finalization of a payment session. It caries:
 *     - `authToken` string, which is used for further API interactions.
 *
 * - `viewInitialized`: Indicates that the Klarna view has been initialized. This is the first step in the Klarna view handling process.
 * - `viewResized(height: CGFloat)`: Represents a change in the view's height, which may occur when the Klarna view adjusts to display different content. The `height` parameter specifies the new height of the view.
 * - `viewLoaded`: Indicates that the Klarna view has finished loading its initial content and is ready for interaction. The `view` parameter represents the klarna view.
 * - `reviewLoaded`: Indicates that the reviewed information has been loaded into the Klarna view.
 * - `isLoading`: Indicates that the Klarna view is still loading.
 */
public enum KlarnaStep: PrimerHeadlessStep {
    /// Session creation
    case paymentSessionCreated(clientToken: String, paymentCategories: [KlarnaPaymentCategory])
    
    /// Session authorization
    case paymentSessionAuthorized(authToken: String, checkoutData: PrimerCheckoutData)
    case paymentSessionFinalizationRequired
    
    /// Session finalization
    case paymentSessionFinalized(authToken: String, checkoutData: PrimerCheckoutData)
    
    /// Payment view handling
    case viewInitialized
    case viewResized(height: CGFloat)
    case viewLoaded(view: UIView?)
    case reviewLoaded
    case notLoaded
}
