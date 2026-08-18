//
//  SwiftUIRenderProbe.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

/// Hosts a SwiftUI view offscreen and forces a layout pass so its `body` — and the bodies of its
/// children — execute, exercising view code that is otherwise only reachable through rendering.
@available(iOS 15.0, *)
@MainActor
enum SwiftUIRenderProbe {
  @discardableResult
  static func render(_ view: some View, width: CGFloat = 390, height: CGFloat = 844) -> Bool {
    let controller = UIHostingController(rootView: view)
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
    window.rootViewController = controller
    // Make the window visible enough to trigger a render pass, but deliberately do NOT call
    // makeKeyAndVisible(): that hijacks the global key window and can break presentation-based
    // tests that run later in the same process. A visible (non-key) window still evaluates bodies.
    window.isHidden = false
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    RunLoop.current.run(until: Date().addingTimeInterval(0.02))
    window.isHidden = true
    window.rootViewController = nil
    return true
  }
}
