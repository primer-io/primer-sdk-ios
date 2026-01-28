//
//  KlarnaState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
public struct KlarnaState: Equatable {

  public enum Step: Equatable {
    case loading
    case categorySelection
    case viewReady
    case authorizationStarted
    case awaitingFinalization
  }

  public private(set) var step: Step

  public private(set) var categories: [KlarnaPaymentCategory]

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
