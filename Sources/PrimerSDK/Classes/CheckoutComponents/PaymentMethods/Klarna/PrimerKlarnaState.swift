//
//  PrimerKlarnaState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// State for the Klarna payment flow, tracking the current step and available categories.
///
/// The Klarna flow progresses through these steps:
/// `loading` → `categorySelection` → `viewReady` → `authorizationStarted` → `awaitingFinalization`
@available(iOS 15.0, *)
public struct PrimerKlarnaState: Equatable {

  /// The current step of the Klarna payment flow.
  public enum Step: Equatable {
    /// Initial loading state while Klarna session is being created.
    case loading
    /// Klarna payment categories are available for selection.
    case categorySelection
    /// The Klarna payment view is loaded and ready to display.
    case viewReady
    /// The user has started the authorization process.
    case authorizationStarted
    /// Authorization succeeded, awaiting finalization to complete payment.
    case awaitingFinalization
  }

  /// The current step of the Klarna payment flow.
  public private(set) var step: Step

  /// Available Klarna payment categories (e.g., Pay Now, Pay Later, Slice It).
  public private(set) var categories: [KlarnaPaymentCategory]

  /// The identifier of the currently selected payment category.
  public private(set) var selectedCategoryId: String?

  public init(
    step: Step = .loading,
    categories: [KlarnaPaymentCategory] = [],
    selectedCategoryId: String? = nil
  ) {
    self.step = step
    self.categories = categories
    self.selectedCategoryId = selectedCategoryId
  }
}
