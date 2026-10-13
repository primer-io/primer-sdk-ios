//
//  ComponentTypeAliases.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

// MARK: - Component Type Aliases

/// Country item customization receiving country data and selection callback
@available(iOS 15.0, *)
typealias CountryItemComponent = (PrimerCountry, @escaping () -> Void) -> any View

// MARK: - Scope-Aware Screen Components
