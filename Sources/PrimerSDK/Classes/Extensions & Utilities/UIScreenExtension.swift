//
//  UIScreenExtension.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

extension UIScreen {

    static var isDarkModeEnabled: Bool {
        // Check if there's an appearance mode override in PrimerSettings
        let uiOptions = PrimerSettings.current.uiOptions
        switch uiOptions.appearanceMode {
        case .light:
            return false
        case .dark:
            return true
        case .system:
            // Fall through to system check
            break
        }

        // Default to system appearance
        return Self.main.traitCollection.userInterfaceStyle == .dark
    }
}
