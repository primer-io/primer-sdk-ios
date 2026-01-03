//
//  AnalyticsEventType.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Enum defining all 13 CheckoutComponents analytics event types.
/// Values match the SCREAMING_SNAKE_CASE format from the Notion spec.
public enum AnalyticsEventType: String, Codable {
    /// SDK starts initialization and begins contacting Primer backend services
    case sdkInitStart = "SDK_INIT_START"

    /// Initialization completes; the SDK has all configuration needed to render checkout
    case sdkInitEnd = "SDK_INIT_END"

    /// Checkout UI is interactive (components rendered or headless ready)
    case checkoutFlowStarted = "CHECKOUT_FLOW_STARTED"

    /// User selects a payment method
    case paymentMethodSelection = "PAYMENT_METHOD_SELECTION"

    /// Required payment details validated (e.g., card form is complete)
    case paymentDetailsEntered = "PAYMENT_DETAILS_ENTERED"

    /// User taps Pay / Continue; before tokenization
    case paymentSubmitted = "PAYMENT_SUBMITTED"

    /// Primer begins processing (card tokenization or APM kickoff)
    case paymentProcessingStarted = "PAYMENT_PROCESSING_STARTED"

    /// Redirect to third-party payment provider
    case paymentRedirectToThirdParty = "PAYMENT_REDIRECT_TO_THIRD_PARTY"

    /// 3DS challenge presented
    case paymentThreeds = "PAYMENT_THREEDS"

    /// Payment completes successfully
    case paymentSuccess = "PAYMENT_SUCCESS"

    /// Payment fails
    case paymentFailure = "PAYMENT_FAILURE"

    /// User retries after a failure
    case paymentReattempted = "PAYMENT_REATTEMPTED"

    /// User leaves the checkout before completion
    case paymentFlowExited = "PAYMENT_FLOW_EXITED"
}
