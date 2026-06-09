//
//  SwiftUIRenderProbe.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

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
    window.makeKeyAndVisible()
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    RunLoop.current.run(until: Date().addingTimeInterval(0.02))
    window.isHidden = true
    window.rootViewController = nil
    return true
  }
}
