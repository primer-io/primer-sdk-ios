//
//  ComponentTypeAliases.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Component Type Aliases

/// Basic UI component returning any View (wrapped in AnyView at usage site internally)
@available(iOS 15.0, *)
public typealias Component = () -> any View

/// Container component that wraps content with custom presentation
@available(iOS 15.0, *)
public typealias ContainerComponent = (@escaping () -> any View) -> any View

/// Error display component receiving error message
@available(iOS 15.0, *)
public typealias ErrorComponent = (String) -> any View

/// Payment method item customization receiving method data
@available(iOS 15.0, *)
public typealias PaymentMethodItemComponent = (CheckoutPaymentMethod) -> any View

/// Country item customization receiving country data and selection callback
@available(iOS 15.0, *)
public typealias CountryItemComponent = (PrimerCountry, @escaping () -> Void) -> any View

/// Category header component receiving category name
@available(iOS 15.0, *)
public typealias CategoryHeaderComponent = (String) -> any View

// MARK: - Scope-Aware Screen Components

/// Screen component receiving PaymentMethodSelectionScope for full customization.
/// Enables merchants to build completely custom payment selection screens with access to
/// payment methods list and navigation actions.
@available(iOS 15.0, *)
public typealias PaymentMethodSelectionScreenComponent =
  (PrimerPaymentMethodSelectionScope) -> any View

/// Screen component receiving CardFormScope for full customization.
/// Enables merchants to build completely custom card forms with access to
/// form state, validation, and submit actions.
@available(iOS 15.0, *)
public typealias CardFormScreenComponent =
  (any PrimerCardFormScope) -> any View

/// Screen component receiving BankSelectorScope for full customization.
/// Enables merchants to build completely custom bank selector screens with access to
/// bank list, search, and selection actions.
@available(iOS 15.0, *)
public typealias BankSelectorScreenComponent =
  (any PrimerBankSelectorScope) -> any View

/// Bank item customization component receiving Bank model for rendering.
@available(iOS 15.0, *)
public typealias BankItemComponent = (Bank) -> any View
