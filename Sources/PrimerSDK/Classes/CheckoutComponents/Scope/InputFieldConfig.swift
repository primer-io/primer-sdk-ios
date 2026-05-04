//
//  InputFieldConfig.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Input Field Configuration

/// Configuration for customizing a text input field.
/// Supports partial customization (label, placeholder, styling) or full component replacement.
///
/// ## Usage Examples
///
/// ### Partial Customization
/// ```swift
/// InputFieldConfig(
///     label: "Card Number",
///     placeholder: "0000 0000 0000 0000",
///     styling: PrimerFieldStyling(borderColor: .blue)
/// )
/// ```
///
/// ### Full Component Replacement
/// ```swift
/// InputFieldConfig(component: { MyCustomCardNumberField() })
/// ```
@available(iOS 15.0, *)
public struct InputFieldConfig {

  /// Custom label text. When nil, uses SDK default label.
  public let label: String?

  /// Custom placeholder text. When nil, uses SDK default placeholder.
  public let placeholder: String?

  /// Custom styling configuration. When nil, uses SDK default styling.
  public let styling: PrimerFieldStyling?

  /// Full component replacement. When provided, label/placeholder/styling are ignored
  /// and the custom component is rendered instead.
  public let component: Component?

  /// Creates a new input field configuration.
  /// - Parameters:
  ///   - label: Custom label text. Default: nil (uses SDK default)
  ///   - placeholder: Custom placeholder text. Default: nil (uses SDK default)
  ///   - styling: Custom styling. Default: nil (uses SDK default)
  ///   - component: Full component replacement. Default: nil (uses SDK default field)
  public init(
    label: String? = nil,
    placeholder: String? = nil,
    styling: PrimerFieldStyling? = nil,
    component: Component? = nil
  ) {
    self.label = label
    self.placeholder = placeholder
    self.styling = styling
    self.component = component
  }
}
