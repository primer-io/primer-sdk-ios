//
//  VaultedPaymentMethodManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Combine
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class VaultedPaymentMethodManager: ObservableObject {

  var onSelectionChanged: ((PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?) -> Void)?

  @Published private(set) var methods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
  @Published private(set) var selectedMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?

  /// The saved methods list's edit mode. Kept here because the list screen is rebuilt when the shopper
  /// comes back from the delete confirmation, and Cancel there must leave the list in edit mode.
  private(set) var isEditing = false

  func setMethods(_ newMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]) {
    methods = newMethods

    // Clear selection if the selected method was deleted
    if let selectedId = selectedMethod?.id,
      !newMethods.contains(where: { $0.id == selectedId }) {
      selectedMethod = nil
    }

    // Set first as default if none selected
    if selectedMethod == nil, let first = newMethods.first {
      selectedMethod = first
    }
  }

  func setSelectedMethod(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?) {
    selectedMethod = method
    onSelectionChanged?(method)
  }

  func setEditing(_ editing: Bool) {
    isEditing = editing
  }
}
