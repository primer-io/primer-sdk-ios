//
//  ProviderComponentView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct ProviderComponentView: UIViewRepresentable {
    let uiView: UIView

    func makeUIView(context: Context) -> UIView { uiView }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
