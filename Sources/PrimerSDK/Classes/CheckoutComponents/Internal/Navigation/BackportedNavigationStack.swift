//
//  BackportedNavigationStack.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct BackportedNavigationStack<Content: View>: View {

  private let content: () -> Content

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
