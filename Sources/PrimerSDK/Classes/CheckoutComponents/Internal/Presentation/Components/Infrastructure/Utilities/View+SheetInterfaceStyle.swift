//
//  View+SheetInterfaceStyle.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

@available(iOS 15.0, *)
extension View {
  /// Forces the scheme on the sheet's own controller. `preferredColorScheme` would also restyle the merchant's screen underneath.
  func sheetInterfaceStyle(_ colorScheme: ColorScheme?) -> some View {
    background(SheetInterfaceStyleView(colorScheme: colorScheme))
  }
}

@available(iOS 15.0, *)
private struct SheetInterfaceStyleView: UIViewControllerRepresentable {
  let colorScheme: ColorScheme?

  func makeUIViewController(context: Context) -> StyleController {
    StyleController()
  }

  func updateUIViewController(_ controller: StyleController, context: Context) {
    controller.style = switch colorScheme {
    case .dark: .dark
    case .light: .light
    default: .unspecified
    }
  }

  final class StyleController: UIViewController {
    var style: UIUserInterfaceStyle = .unspecified {
      didSet { apply() }
    }

    override func didMove(toParent parent: UIViewController?) {
      super.didMove(toParent: parent)
      apply()
    }

    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      apply()
    }

    private func apply() {
      var root: UIViewController = self
      while let parent = root.parent { root = parent }
      root.overrideUserInterfaceStyle = style
    }
  }
}
