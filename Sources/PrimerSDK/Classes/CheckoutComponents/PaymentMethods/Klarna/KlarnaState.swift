//
//  KlarnaState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// State model for Klarna payment method scope.
/// Tracks the current step, available payment categories, and selected category.
@available(iOS 15.0, *)
public struct KlarnaState: Equatable {

    /// The current step of the Klarna payment flow.
    public enum Step: Equatable {
        /// Session is being created or payment view is loading
        case loading
        /// Categories are available for selection
        case categorySelection
        /// Klarna SDK payment view is ready and embedded
        case viewReady
        /// Authorization has been initiated
        case authorizationStarted
        /// Additional finalization step is required
        case awaitingFinalization
    }

    /// Current step of the Klarna flow
    public var step: Step

    /// Available Klarna payment categories (e.g., "Pay now", "Pay later", "Slice it")
    public var categories: [KlarnaPaymentCategory]

    /// The identifier of the currently selected payment category
    public var selectedCategoryId: String?

    /// Default initializer
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
