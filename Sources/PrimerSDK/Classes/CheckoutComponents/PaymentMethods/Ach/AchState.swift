//
//  AchState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
public struct AchState: Equatable {

  public enum Step: Equatable {
    case loading
    case userDetailsCollection
    case bankAccountCollection
    case mandateAcceptance
    case processing
  }

  public struct UserDetails: Equatable {
    public let firstName: String
    public let lastName: String
    public let emailAddress: String

    public init(firstName: String = "", lastName: String = "", emailAddress: String = "") {
      self.firstName = firstName
      self.lastName = lastName
      self.emailAddress = emailAddress
    }
  }

  public struct FieldValidation: Equatable {
    public let firstNameError: String?
    public let lastNameError: String?
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

    public var hasErrors: Bool {
      firstNameError != nil || lastNameError != nil || emailError != nil
    }
  }

  public private(set) var step: Step

  public private(set) var userDetails: UserDetails

  public private(set) var fieldValidation: FieldValidation?

  public private(set) var mandateText: String?

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
