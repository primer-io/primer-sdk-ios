//
//  ExpiryDateInput.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

struct ExpiryDateInput {
  let month: String
  let year: String
}

final class ExpiryDateRule: ValidationRule {

  func validate(_ input: ExpiryDateInput) -> ValidationResult {
    let month = input.month.trimmingCharacters(in: .whitespacesAndNewlines)
    let year = input.year.trimmingCharacters(in: .whitespacesAndNewlines)

    if month.isEmpty, year.isEmpty {
      let error = ErrorMessageResolver.createRequiredFieldError(for: .expiryDate)
      return .invalid(error: error)
    }

    guard let monthInt = Int(month), (1...12).contains(monthInt) else {
      let error = ErrorMessageResolver.createInvalidFieldError(for: .expiryDate, reason: "expiry_month_invalid")
      return .invalid(error: error)
    }

    guard year.count == 2 || year.count == 4, let yearInt = Int(year) else {
      let error = ErrorMessageResolver.createInvalidFieldError(for: .expiryDate, reason: "expiry_year_invalid")
      return .invalid(error: error)
    }

    let now = Date()
    let currentYear = Calendar.current.component(.year, from: now) % 100
    let currentMonth = Calendar.current.component(.month, from: now)

    // Normalize 4-digit year input to 2-digit
    let normalizedYear = yearInt > 99 ? yearInt % 100 : yearInt

    if normalizedYear < currentYear || (normalizedYear == currentYear && monthInt < currentMonth) {
      let error = ValidationError(
        inputElementType: .expiryDate,
        errorId: "card_expired",
        fieldNameKey: "expiry_date_field",
        errorMessageKey: "form_error_card_expired",
        errorFormatKey: nil,
        code: "card-expired",
        message: CheckoutComponentsStrings.formErrorCardExpired
      )
      return .invalid(error: error)
    }

    return .valid
  }
}
