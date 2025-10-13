//
//  Color+CheckoutComponents.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 27.6.25.
//

import SwiftUI

@available(iOS 15.0, *)
extension Color {
    /// Default primary text color (#212121) used as fallback when design tokens are unavailable
    static let defaultTextPrimary = Color(red: 0x21/255, green: 0x21/255, blue: 0x21/255)

    /// Default negative/error icon color (coral red) used as fallback when design tokens are unavailable
    static let defaultIconNegative = Color(red: 1.0, green: 0.45, blue: 0.47)
}
