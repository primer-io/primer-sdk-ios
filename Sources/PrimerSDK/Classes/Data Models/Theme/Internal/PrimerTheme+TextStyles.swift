//
//  PrimerTheme+TextStyles.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

internal enum TextType {
    case body, title, subtitle, amountLabel, system, error
}

final class TextStyle {
    let body, title, subtitle, amountLabel, system, error: TextTheme

    internal init(
        body: TextTheme,
        title: TextTheme,
        subtitle: TextTheme,
        amountLabel: TextTheme,
        system: TextTheme,
        error: TextTheme
    ) {
        self.body = body
        self.title = title
        self.subtitle = subtitle
        self.amountLabel = amountLabel
        self.system = system
        self.error = error
    }
}

final class TextTheme {
    let color: UIColor
    let fontSize: Int

    internal init(color: UIColor, fontSize: Int) {
        self.color = color
        self.fontSize = fontSize
    }
}
