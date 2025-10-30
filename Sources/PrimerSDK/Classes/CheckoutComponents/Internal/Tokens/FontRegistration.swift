//
//  FontRegistration.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Style Dictionary Generator on 30.6.25.
//

import UIKit
import CoreText

/// Utility for registering custom fonts bundled with the SDK
enum FontRegistration {

    private static var isRegistered = false
    private static let lock = NSLock()

    /// Register all custom fonts used by the SDK
    /// This method is idempotent and safe to call multiple times
    static func registerFonts() {
        lock.lock()
        defer { lock.unlock() }

        // Only register once
        guard !isRegistered else { return }

        let fontNames = [
            "InterVariable.ttf"
        ]

        for fontName in fontNames {
            registerFont(named: fontName)
        }

        isRegistered = true
    }

    private static func registerFont(named fontFileName: String) {
        let fontNameWithoutExt = fontFileName.replacingOccurrences(of: ".ttf", with: "")

        // Load font from root level (works for both SPM and CocoaPods)
        guard let fontURL = Bundle.primerResources.url(
            forResource: fontNameWithoutExt,
            withExtension: "ttf"
        ) else {
            return
        }

        guard let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(fontDataProvider) else {
            return
        }

        var error: Unmanaged<CFError>?
        _ = CTFontManagerRegisterGraphicsFont(font, &error)
    }
}
