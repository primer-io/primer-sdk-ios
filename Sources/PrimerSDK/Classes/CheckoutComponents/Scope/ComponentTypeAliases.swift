//
//  ComponentTypeAliases.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
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

/// Country item customization receiving country data
@available(iOS 15.0, *)
public typealias CountryItemComponent = (PrimerCountry) -> any View

/// Category header component receiving category name
@available(iOS 15.0, *)
public typealias CategoryHeaderComponent = (String) -> any View
