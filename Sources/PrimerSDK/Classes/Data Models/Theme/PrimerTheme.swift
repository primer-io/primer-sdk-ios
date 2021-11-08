//
//  PrimerTheme.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 04/01/2021.
//

#if canImport(UIKit)

import UIKit

protocol PrimerThemeProtocol {
    var colors: ColorSwatch { get }
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
public class PrimerTheme: PrimerThemeProtocol {
    
    private let data: PrimerThemeData
    
    internal lazy var colors: ColorSwatch = ColorSwatch(
        primary: data.colors.primary,
        error: data.colors.error
    )
    
    internal lazy var view = data.view.theme(with: data)
    
    internal lazy var text = TextStyle(
        body: data.text.theme(for: .body, with: data),
        title: data.text.theme(for: .title, with: data),
        subtitle: data.text.theme(for: .subtitle, with: data),
        amountLabel: data.text.theme(for: .amountLabel, with: data),
        system: data.text.theme(for: .system, with: data),
        error: data.text.theme(for: .error, with: data)
    )
                      
    internal lazy var paymentMethodButton = data.buttons.theme(for: .paymentMethod, with: data)
    
    internal lazy var mainButton = data.buttons.theme(for: .main, with: data)
    
    internal lazy var input = data.input.theme(with: data)
    
    internal var types = (amount: 1, label: 2, foo: "hello")

    public init(with data: PrimerThemeData = PrimerThemeData()) {
        self.data = data
    }

    // MARK: deprecated methods
    
    @available(iOS 13.0, *)
    @available(*, deprecated)
    public init(
        cornerRadiusTheme: CornerRadiusTheme = CornerRadiusTheme(),
        colorTheme: ColorTheme = PrimerDefaultTheme(),
        darkTheme: ColorTheme = PrimerDarkTheme(),
        layout: PrimerLayout = PrimerLayout(),
        textFieldTheme: PrimerTextFieldTheme = .underlined,
        fontTheme: PrimerFontTheme = PrimerFontTheme()
    ) {
        let theme = DefaultColorTheme(lightTheme: colorTheme, darkTheme: darkTheme)
        
        let data = PrimerThemeData()
        data.colors.primary = theme.tint1
        data.colors.error = theme.error1
        data.view.backgroundColor = theme.main1
        data.view.cornerRadius = cornerRadiusTheme.sheetView
        data.view.safeMargin = layout.safeMargin
        data.text.body.defaultColor = theme.text1
        data.text.title.defaultColor = theme.text1
        data.text.subtitle.defaultColor = theme.neutral1
        data.text.amountLabel.defaultColor = theme.text1
        data.text.system.defaultColor = theme.tint1
        data.text.error.defaultColor = theme.error1
        data.input.backgroundColor = theme.main1
        data.input.cornerRadius = cornerRadiusTheme.textFields
        data.input.border.defaultColor = theme.neutral1
        data.input.border.selectedColor = theme.tint1
        data.input.border.errorColor = theme.error1
        data.input.text.defaultColor = theme.text1
        data.buttons.paymentMethod.defaultColor = theme.main1
        data.buttons.paymentMethod.disabledColor = theme.disabled1
        data.buttons.paymentMethod.cornerRadius = cornerRadiusTheme.buttons
        data.buttons.paymentMethod.border.defaultColor = theme.main1
        data.buttons.paymentMethod.border.selectedColor = theme.tint1
        data.buttons.paymentMethod.text.defaultColor = theme.text1
        data.buttons.paymentMethod.iconColor = theme.text1
        data.buttons.main.defaultColor = theme.tint1
        data.buttons.main.disabledColor = theme.disabled1
        data.buttons.main.cornerRadius = cornerRadiusTheme.buttons
        data.buttons.main.border.defaultColor = theme.tint1
        data.buttons.main.border.selectedColor = theme.tint1
        data.buttons.main.text.defaultColor = theme.text1
        data.buttons.main.iconColor = theme.text1
        self.data = data
    }

    @available(iOS, obsoleted: 13.0)
    @available(*, deprecated)
    public init(
        cornerRadiusTheme: CornerRadiusTheme = CornerRadiusTheme(),
        colorTheme theme: ColorTheme = PrimerDefaultTheme(),
        layout: PrimerLayout = PrimerLayout(),
        textFieldTheme: PrimerTextFieldTheme = .underlined,
        fontTheme: PrimerFontTheme = PrimerFontTheme()
    ) {
        let data = PrimerThemeData()
        data.colors.primary = theme.tint1
        data.colors.error = theme.error1
        data.view.backgroundColor = theme.main1
        data.view.cornerRadius = cornerRadiusTheme.sheetView
        data.view.safeMargin = layout.safeMargin
        data.text.body.defaultColor = theme.text1
        data.text.title.defaultColor = theme.text1
        data.text.subtitle.defaultColor = theme.neutral1
        data.text.amountLabel.defaultColor = theme.text1
        data.text.system.defaultColor = theme.tint1
        data.text.error.defaultColor = theme.error1
        data.input.backgroundColor = theme.main1
        data.input.cornerRadius = cornerRadiusTheme.textFields
        data.input.border.defaultColor = theme.neutral1
        data.input.border.selectedColor = theme.tint1
        data.input.border.errorColor = theme.error1
        data.input.text.defaultColor = theme.text1
        data.buttons.paymentMethod.defaultColor = theme.main1
        data.buttons.paymentMethod.disabledColor = theme.disabled1
        data.buttons.paymentMethod.cornerRadius = cornerRadiusTheme.buttons
        data.buttons.paymentMethod.border.defaultColor = theme.main1
        data.buttons.paymentMethod.border.selectedColor = theme.tint1
        data.buttons.paymentMethod.text.defaultColor = theme.text1
        data.buttons.paymentMethod.iconColor = theme.text1
        data.buttons.main.defaultColor = theme.tint1
        data.buttons.main.disabledColor = theme.disabled1
        data.buttons.main.cornerRadius = cornerRadiusTheme.buttons
        data.buttons.main.border.defaultColor = theme.tint1
        data.buttons.main.border.selectedColor = theme.tint1
        data.buttons.main.text.defaultColor = theme.text1
        data.buttons.main.iconColor = theme.text1
        self.data = data
    }
}

#endif
