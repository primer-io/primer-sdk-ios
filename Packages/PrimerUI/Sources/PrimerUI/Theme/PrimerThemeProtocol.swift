//
//  PrimerThemeProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public protocol PrimerThemeProtocol {
    var colors: ColorSwatch { get }
    var blurView: ViewTheme { get }
    var view: ViewTheme { get }
    var text: TextStyle { get }
    var paymentMethodButton: ButtonTheme { get }
    var mainButton: ButtonTheme { get }
    var input: InputTheme { get }
}
