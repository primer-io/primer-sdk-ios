//
//  Colors.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// MARK: Light

import UIKit
import SwiftUI

public struct PrimerColors {

    private static let lightModeBlack = PrimerColor(red: 0, green: 0, blue: 0)
    private static let lightModeWhite = PrimerColor(red: 255, green: 255, blue: 255)
    private static let lightModeGray = PrimerColor(red: 142, green: 142, blue: 147)
    private static let lightModeLightGray = PrimerColor(red: 229, green: 229, blue: 234)
    private static let lightModeRed = PrimerColor(red: 255, green: 59, blue: 48)
    private static let lightModeBlue = PrimerColor(red: 0, green: 122, blue: 255)
    private static let lightModeYellow = PrimerColor(red: 255, green: 204, blue: 0)
    private static let lightModeGreen = PrimerColor(red: 52, green: 199, blue: 89)

    private static let darkModeBlack = PrimerColor(red: 255, green: 255, blue: 255)
    private static let darkModeWhite = PrimerColor(red: 23, green: 22, blue: 25)
    private static let darkModeGray = PrimerColor(red: 142, green: 142, blue: 147)
    private static let darkModeLightGray = PrimerColor(red: 44, green: 44, blue: 47)
    private static let darkModeRed = PrimerColor(red: 255, green: 69, blue: 58)
    private static let darkModeBlue = PrimerColor(red: 10, green: 132, blue: 255)
    private static let darkModeYellow = PrimerColor(red: 255, green: 214, blue: 10)
    private static let darkModeGreen = PrimerColor(red: 50, green: 215, blue: 75)

    // MARK: defaults
    public static let black: UIColor = PrimerColor.dynamic(lightMode: lightModeBlack, darkMode: darkModeBlack)
    public static let white: UIColor = PrimerColor.dynamic(lightMode: lightModeWhite, darkMode: darkModeWhite)
    public static let gray: UIColor = PrimerColor.dynamic(lightMode: lightModeGray, darkMode: darkModeGray)
    public static let lightGray: UIColor = PrimerColor.dynamic(lightMode: lightModeLightGray, darkMode: darkModeLightGray)
    public static let red: UIColor = PrimerColor.dynamic(lightMode: lightModeRed, darkMode: darkModeRed)
    public static let blue: UIColor = PrimerColor.dynamic(lightMode: lightModeBlue, darkMode: darkModeBlue)
    public static let yellow: UIColor = PrimerColor.dynamic(lightMode: lightModeYellow, darkMode: darkModeYellow)
    public static let green: UIColor = PrimerColor.dynamic(lightMode: lightModeGreen, darkMode: darkModeGreen)

    // MARK: special cases
    static let klarnaPink = UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1)
    static let blurredBackground = UIColor.black.withAlphaComponent(0.4)
}

// Extension to produce a SwiftUI Color which works until iOS 13
extension PrimerColors {
    static func swiftColor(_ uiColor: UIColor) -> Color {
        if #available(iOS 14.0, *) {
            return Color(uiColor)
        } else {
            // For iOS 13, we need to manually convert using components
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0

            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            return Color(
                .sRGB,
                red: Double(red),
                green: Double(green),
                blue: Double(blue),
                opacity: Double(alpha)
            )
        }
    }
}
