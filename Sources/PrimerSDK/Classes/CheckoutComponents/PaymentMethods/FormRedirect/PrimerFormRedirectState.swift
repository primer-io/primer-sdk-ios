//
//  PrimerFormRedirectState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Flow: `ready` -> `submitting` -> `awaitingExternalCompletion` -> `success` | `failure`
@available(iOS 15.0, *)
struct PrimerFormRedirectState: Equatable, @unchecked Sendable {

  /// When switching on this enum, always include a `default` case to handle future additions.
  enum Status: Equatable {
    case ready
    case submitting
    case awaitingExternalCompletion
    case success
    case failure(String)
  }

  var status: Status
  var fields: [PrimerFormFieldState]
  var pendingMessage: String?
  var surchargeAmount: String?

  init(
    status: Status = .ready,
    fields: [PrimerFormFieldState] = [],
    pendingMessage: String? = nil,
    surchargeAmount: String? = nil
  ) {
    self.status = status
    self.fields = fields
    self.pendingMessage = pendingMessage
    self.surchargeAmount = surchargeAmount
  }
}

@available(iOS 15.0, *)
extension PrimerFormRedirectState {

  var isSubmitEnabled: Bool {
    !fields.isEmpty && fields.allSatisfy(\.isValid)
  }

  var otpField: PrimerFormFieldState? {
    fields.first { $0.fieldType == .otpCode }
  }

  var phoneField: PrimerFormFieldState? {
    fields.first { $0.fieldType == .phoneNumber }
  }

  var isLoading: Bool {
    status == .submitting
  }

  var isTerminal: Bool {
    switch status {
    case .success, .failure:
      true
    default:
      false
    }
  }
}
