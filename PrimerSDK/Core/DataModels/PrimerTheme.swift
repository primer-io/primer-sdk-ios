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
    public let buttonColorTheme: ButtonColorTheme
    public let fontColorTheme: FontColorTheme
    public let textFieldTheme: PrimerTextFieldTheme
    public let content = PrimerContent()
    public let layout: PrimerLayout
    
    public init(
        cornerRadiusTheme: CornerRadiusTheme = CornerRadiusTheme(),
        backgroundColor: UIColor = .white,
        buttonColorTheme: ButtonColorTheme = ButtonColorTheme(),
        fontColorTheme: FontColorTheme = FontColorTheme(),
        layout: PrimerLayout = PrimerLayout(),
        textFieldTheme: PrimerTextFieldTheme = .underlined
    ) {
        self.cornerRadiusTheme = cornerRadiusTheme
        self.backgroundColor = backgroundColor
        self.buttonColorTheme = buttonColorTheme
        self.fontColorTheme = fontColorTheme
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
    public let applePay, creditCard, paypal, total, title, payButton: UIColor
    
    public init(
        applePay: UIColor = .white,
        creditCard: UIColor = .black,
        paypal: UIColor = .black,
        total: UIColor = .black,
        title: UIColor = .black,
        payButton: UIColor = .white
    ) {
        self.applePay = applePay
        self.creditCard = creditCard
        self.paypal = paypal
        self.total = total
        self.title = title
        self.payButton = payButton
    }
}

public struct PrimerLayout {
    public let showMainTitle, showTopTitle: Bool
    
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
