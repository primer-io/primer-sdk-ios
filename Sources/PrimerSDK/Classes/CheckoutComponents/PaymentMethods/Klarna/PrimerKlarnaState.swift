//
//  PrimerKlarnaState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Klarna flow: `loading` -> `categorySelection` -> `viewReady` -> `authorizationStarted` -> `awaitingFinalization`
@available(iOS 15.0, *)
public struct PrimerKlarnaState: Equatable, @unchecked Sendable {

  /// When switching on this enum, always include a `default` case to handle future additions.
  public enum Step: Equatable {
    case loading
    case categorySelection
    case viewReady
    case authorizationStarted
    case awaitingFinalization
  }

  public internal(set) var step: Step
  public internal(set) var categories: [KlarnaPaymentCategory]
  public internal(set) var selectedCategoryId: String?

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
