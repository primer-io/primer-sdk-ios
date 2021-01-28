//
//  PrimerTheme.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 04/01/2021.
//

import UIKit

public struct PrimerTheme {
    public let cornerRadiusTheme: CornerRadiusTheme
    public let backgroundColor: UIColor //UIColor(red: 246.0/255.0, green: 246.0/255.0, blue: 246.0/255.0, alpha: 1)
    //    public let buttonColorTheme: ButtonColorTheme
    //    public let fontColorTheme: FontColorTheme
    public let colorTheme: ColorTheme
    public let textFieldTheme: PrimerTextFieldTheme
    public let content = PrimerContent()
    public let layout: PrimerLayout
    
    public init(
        cornerRadiusTheme: CornerRadiusTheme = CornerRadiusTheme(),
        backgroundColor: UIColor = .darkGray,
        //        buttonColorTheme: ButtonColorTheme = ButtonColorTheme(),
        //        fontColorTheme: FontColorTheme = FontColorTheme(),
        lightTheme: ColorTheme? = nil,
        darkTheme: ColorTheme? = nil,
        layout: PrimerLayout = PrimerLayout(),
        textFieldTheme: PrimerTextFieldTheme = .underlined
    ) {
        self.cornerRadiusTheme = cornerRadiusTheme
        self.backgroundColor = backgroundColor
        //        self.buttonColorTheme = buttonColorTheme
        //        self.fontColorTheme = fontColorTheme
        self.colorTheme = DefaultColorTheme(lightTheme: lightTheme ?? LightTheme(), darkTheme: darkTheme ?? DarkTheme())
        self.layout = layout
        self.textFieldTheme = textFieldTheme
    }
}

public struct CornerRadiusTheme {
    public let buttons, textFields: CGFloat
    
    public init(
        buttons: CGFloat = 4,
        textFields: CGFloat = 2
    ) {
        self.buttons = buttons
        self.textFields = textFields
    }
}

public struct ButtonColorTheme {
    public let applePay, creditCard, paypal, payButton: UIColor
    public init(
        applePay: UIColor = .black,
        creditCard: UIColor = .white,
        paypal: UIColor = UIColor(red: 190.0/255.0, green: 228.0/255.0, blue: 254.0/255.0, alpha: 1),
        payButton: UIColor = .systemBlue
    ) {
        self.applePay = applePay
        self.creditCard = creditCard
        self.paypal = paypal
        self.payButton = payButton
    }
}

public struct FontColorTheme {
    public let applePay, creditCard, paypal, total, title, payButton, labels: UIColor
    
    public init(
        applePay: UIColor = .white,
        creditCard: UIColor = .black,
        paypal: UIColor = .black,
        total: UIColor = .black,
        title: UIColor = .black,
        payButton: UIColor = .white,
        labels: UIColor = .systemBlue
    ) {
        self.applePay = applePay
        self.creditCard = creditCard
        self.paypal = paypal
        self.total = total
        self.title = title
        self.payButton = payButton
        self.labels = labels
    }
}

public struct PrimerLayout {
    public let showMainTitle, showTopTitle: Bool
    public let safeMargin: CGFloat = 16.0
    
    public init(
        showMainTitle: Bool = true,
        showTopTitle: Bool = true
    ) {
        self.showMainTitle = showMainTitle
        self.showTopTitle = showTopTitle
    }
}

public enum PrimerTextFieldTheme {
    case outlined, underlined, doublelined
}

public protocol ColorTheme {
    var text1: UIColor { get } // heading
    var text2: UIColor { get } // body
    var text3: UIColor { get } // system
    var main1: UIColor { get } // backgrounds
    var main2: UIColor { get } // cells, default buttons
    var tint1: UIColor { get } // border
    var disabled1: UIColor { get }
    var error1: UIColor { get }
}

struct DefaultColorTheme: ColorTheme {
    var text1: UIColor { return getColor(light: lightTheme.text1, dark: darkTheme.text1) }
    var text2: UIColor { return getColor(light: lightTheme.text2, dark: darkTheme.text2) }
    var text3: UIColor { return getColor(light: lightTheme.text3, dark: darkTheme.text3) }
    var main1: UIColor { return getColor(light: lightTheme.main1, dark: darkTheme.main1) }
    var main2: UIColor { return getColor(light: lightTheme.main2, dark: darkTheme.main2) }
    var tint1: UIColor { return getColor(light: lightTheme.tint1, dark: darkTheme.tint1) }
    var disabled1: UIColor { return getColor(light: lightTheme.disabled1, dark: darkTheme.disabled1) }
    var error1: UIColor { return getColor(light: lightTheme.error1, dark: darkTheme.error1) }
    
    let lightTheme: ColorTheme
    let darkTheme: ColorTheme
    
    init(
        lightTheme: ColorTheme,
        darkTheme: ColorTheme
    ) {
        self.lightTheme = lightTheme
        self.darkTheme = darkTheme
    }
    
    func getColor(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return dark
                } else {
                    return light
                }
            }
        } else {
            return light
        }
    }
}

struct LightTheme: ColorTheme {
    var text1: UIColor
    var text2: UIColor
    var text3: UIColor
    var main1: UIColor
    var main2: UIColor
    var tint1: UIColor
    var disabled1: UIColor
    var error1: UIColor
    
    init(
        text1: UIColor = .black,
        text2: UIColor = .white,
        text3: UIColor = .systemBlue,
        main1: UIColor = .white,
        main2: UIColor = .white,
        tint1: UIColor = .systemBlue,
        disabled1: UIColor = .lightGray,
        error1: UIColor = .systemRed
    ) {
        self.text1 = text1
        self.text2 = text2
        self.text3 = text3
        self.main1 = main1
        self.main2 = main2
        self.tint1 = tint1
        self.disabled1 = disabled1
        self.error1 = error1
    }
}

struct DarkTheme: ColorTheme {
    var text1: UIColor
    var text2: UIColor
    var text3: UIColor
    var main1: UIColor
    var main2: UIColor
    var tint1: UIColor
    var disabled1: UIColor
    var error1: UIColor
    
    init(
        text1: UIColor = .white,
        text2: UIColor = .white,
        text3: UIColor = .systemBlue,
        main1: UIColor = .darkGray,
        main2: UIColor = .gray,
        tint1: UIColor = .systemBlue,
        disabled1: UIColor = .gray,
        error1: UIColor = .systemRed
    ) {
        self.text1 = text1
        self.text2 = text2
        self.text3 = text3
        self.main1 = main1
        self.main2 = main2
        self.tint1 = tint1
        self.disabled1 = disabled1
        self.error1 = error1
    }
}
