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
    internal var colors: ColorSwatch
    internal var view: ViewTheme
    internal var text: TextStyle
    internal var paymentMethodButton: ButtonTheme
    internal var mainButton: ButtonTheme
    internal var input: InputTheme

    public init(with data: PrimerThemeData? = nil) {
        colors = ColorSwatch.default(with: data?.colors)
        view = ViewTheme.default(with: data?.view)
        text = TextStyle.default(with: data?.text)
        input = InputTheme.default(with: data?.input)
        paymentMethodButton = ButtonTheme.paymentMethod(with: data?.buttons?.paymentMethod)
        mainButton = ButtonTheme.main(with: data?.buttons?.main)
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

        colors = ColorSwatch.init(primary: theme.tint1, error: theme.error1)

        view = ViewTheme.init(
            backgroundColor: theme.main1,
            cornerRadius: cornerRadiusTheme.sheetView,
            safeMargin: layout.safeMargin
        )
        
        text = TextStyle.init(
            default: TextTheme.init(color: theme.text1, fontsize: 14),
            title: TextTheme.init(color: theme.text1, fontsize: 20),
            subtitle: TextTheme.init(color: theme.neutral1, fontsize: 12),
            amountLabel: TextTheme.init(color: theme.text1, fontsize: 24),
            system: TextTheme.init(color: theme.tint1, fontsize: 14),
            error: TextTheme.init(color: theme.error1, fontsize: 10)
        )

        input = InputTheme(
            color: theme.main1,
            cornerRadius: cornerRadiusTheme.textFields,
            border: BorderTheme(
                colorStates: StatefulColor(
                    theme.neutral1,
                    disabled: theme.disabled1,
                    selected: theme.tint1
                ),
                width: CGFloat(1.0)
            ),
            text: TextTheme(color: theme.text1, fontsize: 14),
            hintText: TextTheme(color: theme.neutral1, fontsize: 14),
            errortext: TextTheme(color: theme.error1, fontsize: 10),
            inputType: .underlined
        )

        paymentMethodButton = ButtonTheme(
            colorStates: StatefulColor(
                theme.main1,
                disabled: theme.disabled1
            ),
            cornerRadius: cornerRadiusTheme.buttons,
            border: BorderTheme(
                colorStates: StatefulColor(
                    theme.main1,
                    disabled: theme.disabled1
                ),
                width: CGFloat(1.0)
            ),
            text: TextTheme(
                color: theme.main1,
                fontsize: 14
            )
        )
        
        mainButton = ButtonTheme(
            colorStates: StatefulColor(
                theme.main1,
                disabled: theme.disabled1
            ),
            cornerRadius: cornerRadiusTheme.buttons,
            border: BorderTheme(
                colorStates: StatefulColor(
                    theme.main1,
                    disabled: theme.disabled1
                ),
                width: CGFloat(1.0)
            ),
            text: TextTheme(
                color: theme.main1,
                fontsize: 14
            )
        )
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
        colors = ColorSwatch.init(
            primary: theme.tint1,
            error: theme.error1
        )

        view = ViewTheme.init(
            backgroundColor: theme.main1,
            cornerRadius: cornerRadiusTheme.sheetView,
            safeMargin: layout.safeMargin
        )

        text = TextStyle.init(
            default: TextTheme.init(color: theme.text1, fontsize: 14),
            title: TextTheme.init(color: theme.text1, fontsize: 20),
            subtitle: TextTheme.init(color: theme.neutral1, fontsize: 12),
            amountLabel: TextTheme.init(color: theme.text1, fontsize: 24),
            system: TextTheme.init(color: theme.tint1, fontsize: 14),
            error: TextTheme.init(color: theme.error1, fontsize: 10)
        )

        input = InputTheme(
            color: theme.main1,
            cornerRadius: cornerRadiusTheme.textFields,
            border: BorderTheme(
                colorStates: StatefulColor(
                    theme.neutral1,
                    disabled: theme.disabled1,
                    selected: theme.tint1
                ),
                width: CGFloat(1.0)
            ),
            text: TextTheme(color: theme.text1, fontsize: 14),
            hintText: TextTheme(color: theme.neutral1, fontsize: 14),
            errortext: TextTheme(color: theme.error1, fontsize: 10),
            inputType: .underlined
        )

        paymentMethodButton = ButtonTheme(
            colorStates: StatefulColor(
                theme.main1,
                disabled: theme.disabled1
            ),
            cornerRadius: cornerRadiusTheme.buttons,
            border: BorderTheme(
                colorStates: StatefulColor(
                    theme.main1,
                    disabled: theme.disabled1
                ),
                width: CGFloat(1.0)
            ),
            text: TextTheme(
                color: theme.main1,
                fontsize: 14
            )
        )
        
        mainButton = ButtonTheme(
            colorStates: StatefulColor(
                theme.main1,
                disabled: theme.disabled1
            ),
            cornerRadius: cornerRadiusTheme.buttons,
            border: BorderTheme(
                colorStates: StatefulColor(
                    theme.main1,
                    disabled: theme.disabled1
                ),
                width: CGFloat(1.0)
            ),
            text: TextTheme(
                color: theme.main1,
                fontsize: 14
            )
        )
    }
}

#endif
