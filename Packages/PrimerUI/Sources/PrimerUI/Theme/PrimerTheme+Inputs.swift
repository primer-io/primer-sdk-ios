//
//  PrimerTheme+Inputs.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public enum InputType {
    case underlined
}

public final class InputTheme {
    public let color: UIColor
    let cornerRadius: CGFloat
    public let border: BorderTheme
    public let text: TextTheme
    let hintText: TextTheme
    let errortext: TextTheme
    let inputType: InputType

    public init(
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
