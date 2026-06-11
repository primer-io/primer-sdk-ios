//
//  PrimerAchState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// ACH flow: `loading` -> `userDetailsCollection` -> `bankAccountCollection` -> `mandateAcceptance` -> `processing`
@available(iOS 15.0, *)
struct PrimerAchState: Equatable, @unchecked Sendable {

  /// When switching on this enum, always include a `default` case to handle future additions.
  enum Step: Equatable {
    case loading
    case userDetailsCollection
    case bankAccountCollection
    case mandateAcceptance
    case processing
  }

  struct UserDetails: Equatable {
    let firstName: String
    let lastName: String
    let emailAddress: String

    init(firstName: String = "", lastName: String = "", emailAddress: String = "") {
      self.firstName = firstName
      self.lastName = lastName
      self.emailAddress = emailAddress
    }
  }

  struct FieldValidation: Equatable {
    let firstNameError: String?
    let lastNameError: String?
    let emailError: String?

    init(
      firstNameError: String? = nil,
      lastNameError: String? = nil,
      emailError: String? = nil
    ) {
      self.firstNameError = firstNameError
      self.lastNameError = lastNameError
      self.emailError = emailError
    }

    var hasErrors: Bool {
      firstNameError != nil || lastNameError != nil || emailError != nil
    }
  }

  var step: Step
  var userDetails: UserDetails
  var fieldValidation: FieldValidation?
  var mandateText: String?
  var isSubmitEnabled: Bool

  init(
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
