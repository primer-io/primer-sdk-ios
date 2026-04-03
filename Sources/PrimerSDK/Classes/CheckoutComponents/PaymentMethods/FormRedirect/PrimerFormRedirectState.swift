//
//  PrimerFormRedirectState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Flow: `ready` -> `submitting` -> `awaitingExternalCompletion` -> `success` | `failure`
@available(iOS 15.0, *)
public struct PrimerFormRedirectState: Equatable, @unchecked Sendable {

  /// When switching on this enum, always include a `default` case to handle future additions.
  public enum Status: Equatable {
    case ready
    case submitting
    case awaitingExternalCompletion
    case success
    case failure(String)
  }

  public internal(set) var status: Status
  public internal(set) var fields: [PrimerFormFieldState]
  public internal(set) var pendingMessage: String?
  public internal(set) var surchargeAmount: String?

  public init(
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

  public var isSubmitEnabled: Bool {
    !fields.isEmpty && fields.allSatisfy(\.isValid)
  }

  public var otpField: PrimerFormFieldState? {
    fields.first { $0.fieldType == .otpCode }
  }

  public var phoneField: PrimerFormFieldState? {
    fields.first { $0.fieldType == .phoneNumber }
  }

  public var isLoading: Bool {
    status == .submitting
  }

  public var isTerminal: Bool {
    switch status {
    case .success, .failure:
      true
    default:
      false
    }
  }
}
