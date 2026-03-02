//
//  PrimerTheme+TextStyles.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public enum TextType {
    case body, title, subtitle, amountLabel, system, error
}

public final class TextStyle {
    public let body, title, subtitle, amountLabel, system, error: TextTheme

    public init(
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

public final class TextTheme {
    public let color: UIColor
    public let fontSize: Int

    public init(color: UIColor, fontSize: Int) {
        self.color = color
        self.fontSize = fontSize
    }
}
