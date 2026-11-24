//
//  UISwitchRepresentable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

struct UISwitchRepresentable: UIViewRepresentable {
    let isOn: Bool
    func makeUIView(context: Context) -> UISwitch { UISwitch() }
    func updateUIView(_ uiView: UISwitch, context: Context) { uiView.isOn = isOn }
}
