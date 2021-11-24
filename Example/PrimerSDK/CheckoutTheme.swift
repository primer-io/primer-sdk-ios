//
//  CheckoutTheme.swift
//  PrimerSDK_Example
//
//  Created by Carl Eriksson on 13/10/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PrimerSDK

private let tropical1 = UIColor(red: 0/255, green: 112/255, blue: 67/255, alpha: 1)
private let tropical2 = UIColor(red: 255/255, green: 170/255, blue: 176/255, alpha: 1)
private let tropical3 = UIColor(red: 255/255, green: 208/255, blue: 131/255, alpha: 1)
private let tropical4 = UIColor(red: 188/255, green: 234/255, blue: 246/255, alpha: 1)
private let tropical5 = UIColor(red: 200/255, green: 98/255, blue: 24/255, alpha: 1)
private let tropical6 = UIColor(red: 3/255, green: 145/255, blue: 155/255, alpha: 1)
private let tropical7 = UIColor(red: 236/255, green: 80/255, blue: 100/255, alpha: 1)
private let tropical8 = UIColor(red: 10/255, green: 89/255, blue: 71/255, alpha: 1)
private let tropical9 = UIColor(red: 31/255, green: 130/255, blue: 118/255, alpha: 1)
private let tropical10 = UIColor(red: 230/255, green: 244/255, blue: 190/255, alpha: 1)

struct CheckoutTheme {
    
    static var tropical: PrimerTheme {
        let data = PrimerThemeData()
        data.colors.primary = tropical7
        data.colors.gray = tropical3
        data.colors.light = tropical10
        data.view.backgroundColor = tropical1
        data.text.title = PrimerThemeData.Text(defaultColor: tropical10)
        data.text.amountLabel = PrimerThemeData.Text(defaultColor: tropical10)
        data.text.subtitle = PrimerThemeData.Text(defaultColor: tropical3)
        data.text.body = PrimerThemeData.Text(defaultColor: .white)
        data.text.system = PrimerThemeData.Text(defaultColor: tropical4)
        data.buttons.paymentMethod.border.defaultColor = tropical8
        data.buttons.paymentMethod.border.selectedColor = tropical8
        data.buttons.paymentMethod.text.defaultColor = tropical8
        data.buttons.paymentMethod.iconColor = tropical8
        data.buttons.main.text.defaultColor = tropical4
        data.buttons.main.disabledColor = tropical9
        data.input.border = PrimerThemeData.Border(defaultColor: tropical4, selectedColor: tropical4)
        data.input.text = PrimerThemeData.Text(defaultColor: tropical4)
        return PrimerTheme.init(with: data)
    }
    
    static var primer: PrimerTheme {
        let data = PrimerThemeData()
        data.colors.primary = .black
        data.colors.gray = UIColor(red: 142.0/255, green: 142.0/255, blue: 147.0/255, alpha: 1.0)
        data.colors.light = .white
        data.blurView.backgroundColor = .black.withAlphaComponent(0.4)
        data.view.backgroundColor = .white
        data.text.title = PrimerThemeData.Text(defaultColor: .black)
        data.text.amountLabel = PrimerThemeData.Text(defaultColor: .black)
        data.text.subtitle = PrimerThemeData.Text(defaultColor: UIColor(red: 142.0/255, green: 142.0/255, blue: 147.0/255, alpha: 1.0))
        data.text.body = PrimerThemeData.Text(defaultColor: .black)
        data.text.system = PrimerThemeData.Text(defaultColor: .white)
        data.buttons.paymentMethod.border.defaultColor = .black
        data.buttons.paymentMethod.border.selectedColor = .blue
        data.buttons.paymentMethod.text.defaultColor = .black
        data.buttons.paymentMethod.iconColor = .clear
        data.buttons.main.text.defaultColor = .blue
        data.buttons.main.defaultColor = .blue
        data.buttons.main.disabledColor = .lightGray
        data.buttons.main.text.defaultColor = .white
        data.input.border = PrimerThemeData.Border(defaultColor: UIColor(red: 142.0/255, green: 142.0/255, blue: 147.0/255, alpha: 1.0), selectedColor: .blue)
        data.input.text = PrimerThemeData.Text(defaultColor: .black)
        data.buttons.paymentMethod.border.width = 1.0
        return PrimerTheme.init(with: data)
    }
}
