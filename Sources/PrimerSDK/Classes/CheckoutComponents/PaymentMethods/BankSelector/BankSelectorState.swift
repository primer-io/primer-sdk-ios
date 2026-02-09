//
//  BankSelectorState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Public state model for the bank selector payment flow.
/// Exposed to merchants via AsyncStream for building custom UIs.
@available(iOS 15.0, *)
public struct BankSelectorState: Equatable {

  /// Current phase of the bank selection flow.
  public enum Status: Equatable {
    /// Bank list is being fetched from the API.
    case loading
    /// Bank list loaded and displayed; user can search and select.
    case ready
    /// User has selected a bank; payment flow handed to checkout scope.
    case selected(Bank)
  }

  /// Current status of the bank selection flow.
  public var status: Status
  /// Full list of available banks (empty during loading).
  public var banks: [Bank]
  /// Banks filtered by search query (equals `banks` when no search).
  public var filteredBanks: [Bank]
  /// The bank the customer selected (nil until selection).
  public var selectedBank: Bank?
  /// Current search text (empty string by default).
  public var searchQuery: String

  public init(
    status: Status = .loading,
    banks: [Bank] = [],
    filteredBanks: [Bank] = [],
    selectedBank: Bank? = nil,
    searchQuery: String = ""
  ) {
    self.status = status
    self.banks = banks
    self.filteredBanks = filteredBanks
    self.selectedBank = selectedBank
    self.searchQuery = searchQuery
  }
}
