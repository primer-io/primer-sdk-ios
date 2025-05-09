//
//  UIScreenExtension.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 03/07/22.
//

import UIKit

extension UIScreen {

    static var isDarkModeEnabled: Bool {
        return main.traitCollection.userInterfaceStyle == .dark
    }
}
