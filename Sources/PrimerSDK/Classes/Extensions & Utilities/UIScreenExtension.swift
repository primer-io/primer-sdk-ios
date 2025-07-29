//
//  UIScreenExtension.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

extension UIScreen {

    static var isDarkModeEnabled: Bool {
        return Self.main.traitCollection.userInterfaceStyle == .dark
    }
}
