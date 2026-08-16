//
//  MockDesignTokens.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable all

@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

#if DEBUG
  import SwiftUI

  /// Mock design tokens for SwiftUI previews and testing
  /// Provides convenient access to both light and dark theme tokens
  @available(iOS 15.0, *)
  struct MockDesignTokens {

    // MARK: - Static Instances

    /// Light theme design tokens with default Primer values
    static let light: DesignTokens = {
      // Create instance with default values
      DesignTokens()
    }()

    /// Dark theme design tokens, resolved through the same JSON pipeline production uses.
    /// Hand-copying primitives here previously left every semantic token at its light value,
    /// so dark-mode previews showed light colours and hid real regressions.
    static let dark: DesignTokens = {
      (try? DesignTokensManager.makeTokens(for: .dark)) ?? DesignTokens()
    }()

    // MARK: - Custom Token Creation

    /// Creates a custom DesignTokens instance for testing specific scenarios
    /// - Parameter modifications: A closure to modify the default light theme tokens
    /// - Returns: A customized DesignTokens instance
    static func custom(modifications: (DesignTokens) -> Void) -> DesignTokens {
      let tokens = DesignTokens()
      modifications(tokens)
      return tokens
    }
  }

#endif  // DEBUG
// swiftlint:enable all
