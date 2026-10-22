//
//  PrimerKlarnaState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Klarna flow: `loading` -> `categorySelection` -> `viewReady` -> `authorizationStarted` -> `awaitingFinalization`
@available(iOS 15.0, *)
struct PrimerKlarnaState: Equatable, @unchecked Sendable {

  /// When switching on this enum, always include a `default` case to handle future additions.
  enum Step: Equatable {
    case loading
    case categorySelection
    case viewReady
    case authorizationStarted
    case awaitingFinalization
  }

  var step: Step
  var categories: [KlarnaPaymentCategory]
  var selectedCategoryId: String?
  var paymentViewHeight: CGFloat
  var isSelectedOptionReady: Bool

  init(
    step: Step = .loading,
    categories: [KlarnaPaymentCategory] = [],
    selectedCategoryId: String? = nil,
    paymentViewHeight: CGFloat = 0,
    isSelectedOptionReady: Bool = false
  ) {
    self.step = step
    self.categories = categories
    self.selectedCategoryId = selectedCategoryId
    self.paymentViewHeight = paymentViewHeight
    self.isSelectedOptionReady = isSelectedOptionReady
  }
}
