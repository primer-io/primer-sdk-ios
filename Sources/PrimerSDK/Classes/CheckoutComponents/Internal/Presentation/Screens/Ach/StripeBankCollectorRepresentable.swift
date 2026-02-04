//
//  StripeBankCollectorRepresentable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

@available(iOS 15.0, *)
struct StripeBankCollectorRepresentable: UIViewControllerRepresentable {
  let viewController: UIViewController

  func makeUIViewController(context: Context) -> UIViewController {
    viewController
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    // No updates needed - the Stripe collector manages its own state
  }
}
