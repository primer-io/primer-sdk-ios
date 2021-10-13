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
        
        let viewTheme = ViewThemeData()
        viewTheme.backgroundColor = tropical1
        
        let text = TextStyleData()
        text.title = TextThemeData(defaultColor: tropical10)
        text.amountLabel = TextThemeData(defaultColor: tropical10)
        text.subtitle = TextThemeData(defaultColor: tropical3)
        text.default = TextThemeData(defaultColor: .white)
        text.system = TextThemeData(defaultColor: tropical4)
        
        let buttons = ButtonStyleData()
        let buttonBorder = BorderThemeData(defaultColor: .white, selectedColor: .white)
        let buttonText = TextThemeData(defaultColor: .white)
        buttons.paymentMethod = ButtonThemeData(text: buttonText, border: buttonBorder)
        
        let mainButtonBorder = BorderThemeData(defaultColor: tropical2, selectedColor: tropical2)
        let mainButtonText = TextThemeData(defaultColor: tropical4)
        buttons.main = ButtonThemeData()
        buttons.main?.defaultColor = tropical2
        buttons.main?.disabledColor = tropical2
        buttons.main?.text = mainButtonText
        buttons.main?.border = mainButtonBorder
        
        let input = InputThemeData()
        input.border = BorderThemeData(defaultColor: .white, selectedColor: .white)
        input.text = TextThemeData(defaultColor: .white)
        
        let data = PrimerThemeData.init(
            view: viewTheme,
            text: text,
            buttons: buttons,
            input: input
        )
        
        return PrimerTheme.init(with: data)
    }
}
