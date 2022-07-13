//
//  UIScreenExtension.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 03/07/22.
//

#if canImport(UIKit)

import UIKit

extension UIScreen {
    
    static var isDarkModeEnabled: Bool {
        if #available(iOS 12.0, *) {
            return Self.main.traitCollection.userInterfaceStyle == .dark
        } else {
            return false
        }
    }
}

#endif
