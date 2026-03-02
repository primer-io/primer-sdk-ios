//
//  PrimerTheme.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerUI
import UIKit

/**
 Struct that customizes Primer's drop-in User Interface

 *Values*

 `cornerRadiusTheme` Modifies the corner radius on elements such as button, textfield, etc.

 `colorTheme` Modifies the color on elements such as labels (headings, titles, body, etc), textfields, etc.

 `textFieldTheme` Enum that modifies textfields' outline, possible values are **outlined**, **underlined**, **doublelined**.

 `fontTheme` Modifies the font of the dop-in UI. Pre-requisites: Include the font in your app.

 `textFieldTheme` Enum that modifies textfields' outline, possible values are **outlined**, **underlined**, **doublelined**.

 `content` Modifies the form's format.

 `layout` Defines the layout of the form.

 `shadowTheme` Modifies the drop shadow of elements.

 - Author:
 Primer
 - Version:
 1.2.2
 */
public final class PrimerTheme: PrimerThemeProtocol {

    private let data: PrimerThemeData

    public lazy var colors: ColorSwatch = ColorSwatch(
        primary: data.colors.primary,
        error: data.colors.error
    )

    public lazy var blurView = data.blurView.theme(for: .blurredBackground, with: data)
    public lazy var view = data.view.theme(for: .main, with: data)

    public lazy var text = TextStyle(
        body: data.text.theme(for: .body, with: data),
        title: data.text.theme(for: .title, with: data),
        subtitle: data.text.theme(for: .subtitle, with: data),
        amountLabel: data.text.theme(for: .amountLabel, with: data),
        system: data.text.theme(for: .system, with: data),
        error: data.text.theme(for: .error, with: data)
    )

    public lazy var paymentMethodButton = data.buttons.theme(for: .paymentMethod, with: data)

    public lazy var mainButton = data.buttons.theme(for: .main, with: data)

    public lazy var input = data.input.theme(with: data)

    public init(with data: PrimerThemeData = PrimerThemeData()) {
        self.data = data
    }
}
