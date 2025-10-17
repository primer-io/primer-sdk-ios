//
//  PrimerTheme.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

protocol PrimerThemeProtocol {
    var colors: ColorSwatch { get }
    var blurView: ViewTheme { get }
    var view: ViewTheme { get }
    var text: TextStyle { get }
    var paymentMethodButton: ButtonTheme { get }
    var mainButton: ButtonTheme { get }
    var input: InputTheme { get }
}

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

    lazy var colors: ColorSwatch = ColorSwatch(
        primary: data.colors.primary,
        error: data.colors.error
    )

    lazy var blurView = data.blurView.theme(for: .blurredBackground, with: data)
    lazy var view = data.view.theme(for: .main, with: data)

    lazy var text = TextStyle(
        body: data.text.theme(for: .body, with: data),
        title: data.text.theme(for: .title, with: data),
        subtitle: data.text.theme(for: .subtitle, with: data),
        amountLabel: data.text.theme(for: .amountLabel, with: data),
        system: data.text.theme(for: .system, with: data),
        error: data.text.theme(for: .error, with: data)
    )

    lazy var paymentMethodButton = data.buttons.theme(for: .paymentMethod, with: data)

    lazy var mainButton = data.buttons.theme(for: .main, with: data)

    lazy var input = data.input.theme(with: data)

    public init(with data: PrimerThemeData = PrimerThemeData()) {
        self.data = data
    }
}

// MARK: - Equatable Conformance

extension PrimerTheme: Equatable {
    /// Compare themes for equality
    /// - Note: Uses identity comparison since PrimerTheme is a reference type.
    ///         Two themes are considered equal if they reference the same instance.
    public static func == (lhs: PrimerTheme, rhs: PrimerTheme) -> Bool {
        return lhs === rhs
    }
}
