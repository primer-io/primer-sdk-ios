//
//  View+Anchored.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
extension View {
  func anchored(to anchor: WeakBox<UIView>?) -> some View {
    background(anchor.map(AnchorReader.init(anchor:)))
  }
}

@available(iOS 15.0, *)
private struct AnchorReader: UIViewRepresentable {
  let anchor: WeakBox<UIView>

  func makeUIView(context _: Context) -> UIView {
    let view = UIView()
    view.isUserInteractionEnabled = false
    return view
  }

  func updateUIView(_ uiView: UIView, context _: Context) {
    anchor.instance = uiView
  }
}
