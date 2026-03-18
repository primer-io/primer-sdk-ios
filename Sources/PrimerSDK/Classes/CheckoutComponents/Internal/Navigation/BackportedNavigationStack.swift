//
//  BackportedNavigationStack.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A compatibility wrapper that uses NavigationStack on iOS 16+ and NavigationView on iOS 15.
/// This ensures consistent navigation behavior across iOS versions.
@available(iOS 15.0, *)
struct BackportedNavigationStack<Content: View>: View {

  private let content: () -> Content

  /// Creates a navigation container with the appropriate navigation style for the current iOS version.
  /// - Parameter content: The content to display within the navigation container.
  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  var body: some View {
    if #available(iOS 16.0, *) {
      NavigationStack {
        content()
      }
    } else {
      NavigationView {
        content()
      }
      .navigationViewStyle(.stack)
    }
  }
}
