//
//  ComponentTypeAliases.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Component Type Aliases

/// Basic UI component returning type-erased view
@available(iOS 15.0, *)
public typealias Component = () -> AnyView

/// Container component that wraps content with custom presentation
@available(iOS 15.0, *)
public typealias ContainerComponent = (@escaping () -> AnyView) -> AnyView

/// Error display component receiving error message
@available(iOS 15.0, *)
public typealias ErrorComponent = (String) -> AnyView

/// Payment method item customization receiving method data
@available(iOS 15.0, *)
public typealias PaymentMethodItemComponent = (CheckoutPaymentMethod) -> AnyView

/// Country item customization receiving country data
@available(iOS 15.0, *)
public typealias CountryItemComponent = (PrimerCountry) -> AnyView
