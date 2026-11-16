//
//  Props.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

protocol Props: UI {
    var padding: CodableValue? { get }
    var spacing: CodableValue? { get }
    var minHeight: Length? { get }
    var backgroundColor: String? { get }
    var borderRadius: Length? { get }
    var borderColor: String? { get }
    var borderWidth: Double? { get }
    var justifyContent: JustifyContent { get }
    var width: Size { get }
    var height: Size { get }
    var frameAlignment: Alignment { get }
}
