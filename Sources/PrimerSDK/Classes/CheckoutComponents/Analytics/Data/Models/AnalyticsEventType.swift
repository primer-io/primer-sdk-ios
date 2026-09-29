//
//  AnalyticsEventType.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Enum defining all CheckoutComponents analytics event types.
/// Values match the SCREAMING_SNAKE_CASE format from the Notion spec.
public enum AnalyticsEventType: String, Codable, Sendable, CaseIterable {
  /// SDK starts initialization and begins contacting Primer backend services
  case sdkInitStart = "SDK_INIT_START"

  /// Initialization completes; the SDK has all configuration needed to render checkout
  case sdkInitEnd = "SDK_INIT_END"

  /// Checkout UI is interactive (components rendered or headless ready)
  case checkoutFlowStarted = "CHECKOUT_FLOW_STARTED"

  /// User selects a payment method
  case paymentMethodSelection = "PAYMENT_METHOD_SELECTION"

  /// Shopper leaves an entered payment method without paying, or the merchant aborts it
  case paymentMethodUnselected = "PAYMENT_METHOD_UNSELECTED"

  /// Every required card field has a value
  case paymentDetailsEntered = "PAYMENT_DETAILS_ENTERED"

  /// Shopper did their part (valid card sent, wallet authorized, returned from redirect)
  case paymentSubmitted = "PAYMENT_SUBMITTED"

  /// After the merchant gate, right before the first request to Primer
  case paymentProcessingStarted = "PAYMENT_PROCESSING_STARTED"

  /// Third-party page or app opened
  case paymentRedirectToThirdParty = "PAYMENT_REDIRECT_TO_THIRD_PARTY"

  /// Third party returned control with a result
  case paymentReturnedFromThirdParty = "PAYMENT_RETURNED_FROM_THIRD_PARTY"

  /// Redirect method failed because `urlScheme` is missing or invalid
  case redirectReturnUrlNotConfigured = "REDIRECT_RETURN_URL_NOT_CONFIGURED"

  /// 3DS challenge shown
  case paymentThreeds = "PAYMENT_THREEDS"

  /// Payment completes successfully
  case paymentSuccess = "PAYMENT_SUCCESS"

  /// Payment fails
  case paymentFailure = "PAYMENT_FAILURE"

  /// User retries after a failure
  case paymentReattempted = "PAYMENT_REATTEMPTED"

  /// User leaves the checkout before completion
  case paymentFlowExited = "PAYMENT_FLOW_EXITED"

  // MARK: - Vault events

  /// Shopper opens the vaulted-methods list ("Show all")
  case vaultListOpened = "VAULT_LIST_OPENED"

  /// Shopper selects a different vaulted method from the list
  case vaultMethodSelected = "VAULT_METHOD_SELECTED"

  /// Shopper leaves the vaulted list to see the other payment methods
  case vaultOtherPayMethodsRequested = "VAULT_OTHER_PAY_METHODS_REQUESTED"

  /// Edit mode entered on the vaulted-methods list
  case vaultEditModeEntered = "VAULT_EDIT_MODE_ENTERED"

  /// Edit mode exited via the Done action
  case vaultEditModeExited = "VAULT_EDIT_MODE_EXITED"

  /// Shopper taps delete on a vaulted method row
  case vaultDeletionRequested = "VAULT_DELETION_REQUESTED"

  /// Delete confirmation dismissed via the Cancel button (not Done/Back)
  case vaultDeletionCancelled = "VAULT_DELETION_CANCELLED"

  /// Vaulted method deleted; carries the promoted method when the active one was deleted and
  /// another was promoted in its place
  case vaultMethodDeleted = "VAULT_METHOD_DELETED"

  /// Deleting a vaulted method failed
  case vaultMethodDeletionFailed = "VAULT_METHOD_DELETION_FAILED"

  /// CVV recapture input shown for a vaulted card
  case vaultCvvRequiredRendered = "VAULT_CVV_REQUIRED_RENDERED"

  /// Vaulted payment submitted with a recaptured CVV
  case vaultCvvSubmitted = "VAULT_CVV_SUBMITTED"

  /// CVV recapture input dismissed without submitting
  case vaultCvvRequiredDismissed = "VAULT_CVV_REQUIRED_DISMISSED"

  /// Vaulted payment submission with recaptured CVV failed
  case vaultCvvSubmissionFailed = "VAULT_CVV_SUBMISSION_FAILED"
}

extension AnalyticsEventType {
  /// Vault events carry `VaultEvent` metadata instead of payment metadata
  var isVaultEvent: Bool { rawValue.hasPrefix("VAULT_") }
}
