//
//  PrimerAchState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// State for the ACH payment flow, tracking the current step and user-entered data.
///
/// The ACH flow progresses through these steps:
/// `loading` → `userDetailsCollection` → `bankAccountCollection` → `mandateAcceptance` → `processing`
@available(iOS 15.0, *)
public struct PrimerAchState: Equatable {

  /// The current step of the ACH payment flow.
  public enum Step: Equatable {
    /// Initial loading state while the ACH flow is being set up.
    case loading
    /// Collecting user details (first name, last name, email).
    case userDetailsCollection
    /// Presenting the bank account collector (Stripe SDK).
    case bankAccountCollection
    /// Displaying the ACH mandate for user acceptance.
    case mandateAcceptance
    /// Processing the payment after mandate acceptance.
    case processing
  }

  /// User-provided details for the ACH payment.
  public struct UserDetails: Equatable {
    /// The user's first name.
    public let firstName: String
    /// The user's last name.
    public let lastName: String
    /// The user's email address.
    public let emailAddress: String

    public init(firstName: String = "", lastName: String = "", emailAddress: String = "") {
      self.firstName = firstName
      self.lastName = lastName
      self.emailAddress = emailAddress
    }
  }

  /// Validation errors for the user details form fields.
  public struct FieldValidation: Equatable {
    /// Error message for the first name field, or nil if valid.
    public let firstNameError: String?
    /// Error message for the last name field, or nil if valid.
    public let lastNameError: String?
    /// Error message for the email field, or nil if valid.
    public let emailError: String?

    public init(
      firstNameError: String? = nil,
      lastNameError: String? = nil,
      emailError: String? = nil
    ) {
      self.firstNameError = firstNameError
      self.lastNameError = lastNameError
      self.emailError = emailError
    }

    /// Whether any field has a validation error.
    public var hasErrors: Bool {
      firstNameError != nil || lastNameError != nil || emailError != nil
    }
  }

  /// The current step of the ACH payment flow.
  public private(set) var step: Step

  /// The user-entered details for the ACH payment.
  public private(set) var userDetails: UserDetails

  /// Validation errors for user details fields, nil when no validation has run.
  public private(set) var fieldValidation: FieldValidation?

  /// The ACH mandate text to display for user acceptance.
  public private(set) var mandateText: String?

  /// Whether the submit/continue button should be enabled.
  public private(set) var isSubmitEnabled: Bool

  public init(
    step: Step = .loading,
    userDetails: UserDetails = UserDetails(),
    fieldValidation: FieldValidation? = nil,
    mandateText: String? = nil,
    isSubmitEnabled: Bool = false
  ) {
    self.step = step
    self.userDetails = userDetails
    self.fieldValidation = fieldValidation
    self.mandateText = mandateText
    self.isSubmitEnabled = isSubmitEnabled
  }
}
