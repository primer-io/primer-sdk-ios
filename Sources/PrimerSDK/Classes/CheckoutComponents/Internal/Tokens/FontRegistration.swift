//
//  FontRegistration.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import CoreText
import UIKit

/// Utility for registering custom fonts bundled with the SDK
enum FontRegistration: LogReporter {

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
            logger.error(message: "⚠️ [FontRegistration] Failed to locate font file: \(fontFileName)")
            return
        }

        guard let fontDataProvider = CGDataProvider(url: fontURL as CFURL) else {
            logger.error(message: "⚠️ [FontRegistration] Failed to create data provider for: \(fontFileName)")
            return
        }

        guard let font = CGFont(fontDataProvider) else {
            logger.error(message: "⚠️ [FontRegistration] Failed to create CGFont from: \(fontFileName)")
            return
        }

        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterGraphicsFont(font, &error)

        if !success, let error = error?.takeRetainedValue() {
            logger.error(message: "⚠️ [FontRegistration] Failed to register font \(fontFileName): \(error)")
        }
    }
}
