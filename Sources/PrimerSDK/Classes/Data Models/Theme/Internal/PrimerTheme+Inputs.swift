//
//  PrimerTheme+Inputs.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

enum InputType {
    case underlined
}

final class InputTheme {
    let color: UIColor
    let cornerRadius: CGFloat
    let border: BorderTheme
    let text: TextTheme
    let hintText: TextTheme
    let errortext: TextTheme
    let inputType: InputType

    internal init(
        color: UIColor,
        cornerRadius: CGFloat,
        border: BorderTheme,
        text: TextTheme,
        hintText: TextTheme,
        errortext: TextTheme,
        inputType: InputType
    ) {
        self.color = color
        self.cornerRadius = cornerRadius
        self.border = border
        self.text = text
        self.hintText = hintText
        self.errortext = errortext
        self.inputType = inputType
    }
}
