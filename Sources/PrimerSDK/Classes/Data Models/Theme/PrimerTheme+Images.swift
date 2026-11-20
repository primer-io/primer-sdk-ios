//
//  PrimerTheme+Images.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
import UIKit

extension PrimerTheme {

    final class BaseImage {

        var colored: UIImage?
        var light: UIImage?
        var dark: UIImage?

        init?(colored: UIImage?, light: UIImage?, dark: UIImage?) {
            self.colored = colored
            self.light = light
            self.dark = dark

            if self.colored == nil, self.light == nil, self.dark == nil {
                return nil
            }
        }

        func image(isDark: Bool) -> UIImage? {
            schemeVariant(isDark: isDark, colored: colored, light: light, dark: dark)
        }
    }

    public final class BaseColoredURLs: Codable {

        var coloredUrlStr: String?
        var darkUrlStr: String?
        var lightUrlStr: String?

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case coloredUrlStr = "colored"
            case darkUrlStr = "dark"
            case lightUrlStr = "light"
        }

        init?(
            coloredUrlStr: String?,
            lightUrlStr: String?,
            darkUrlStr: String?
        ) {
            self.coloredUrlStr = coloredUrlStr
            self.lightUrlStr = lightUrlStr
            self.darkUrlStr = darkUrlStr
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            coloredUrlStr = (try? container.decode(String?.self, forKey: .coloredUrlStr)) ?? nil
            lightUrlStr = (try? container.decode(String?.self, forKey: .lightUrlStr)) ?? nil
            darkUrlStr = (try? container.decode(String?.self, forKey: .darkUrlStr)) ?? nil

            if coloredUrlStr == nil, lightUrlStr == nil, darkUrlStr == nil {
                throw handled(error: InternalError.failedToDecode(message: "BaseColoredURLs"))
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(coloredUrlStr, forKey: .coloredUrlStr)
            try? container.encode(lightUrlStr, forKey: .lightUrlStr)
            try? container.encode(darkUrlStr, forKey: .darkUrlStr)
        }
    }

    public final class BaseColors: Codable {

        var coloredHex: String?
        var darkHex: String?
        var lightHex: String?

        /// Resolves per trait collection, so a colour-scheme change repaints it wherever it is drawn.
        var uiColor: UIColor? {
            // a malformed hex keeps the old one-shot resolution rather than leaking the other scheme's colour
            guard let light = hex(isDark: false)?.hexToUIColor(), let dark = hex(isDark: true)?.hexToUIColor() else {
                return hex(isDark: UIScreen.isDarkModeEnabled)?.hexToUIColor()
            }
            return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case coloredHex = "colored"
            case darkHex = "dark"
            case lightHex = "light"
        }

        init?(
            coloredHex: String?,
            lightHex: String?,
            darkHex: String?
        ) {
            self.coloredHex = coloredHex
            self.lightHex = lightHex
            self.darkHex = darkHex
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            coloredHex = (try? container.decode(String?.self, forKey: .coloredHex)) ?? nil
            darkHex = (try? container.decode(String?.self, forKey: .darkHex)) ?? nil
            lightHex = (try? container.decode(String?.self, forKey: .lightHex)) ?? nil

            if coloredHex == nil, lightHex == nil, darkHex == nil {
                throw handled(error: InternalError.failedToDecode(message: "BaseColors"))
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(coloredHex, forKey: .coloredHex)
            try? container.encode(darkHex, forKey: .darkHex)
            try? container.encode(lightHex, forKey: .lightHex)
        }

        func hex(isDark: Bool) -> String? {
            schemeVariant(isDark: isDark, colored: coloredHex, light: lightHex, dark: darkHex)
        }
    }

    public final class BaseBorderWidth: Codable {

        var colored: CGFloat?
        var dark: CGFloat?
        var light: CGFloat?

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case colored
            case dark
            case light
        }

        /// Resolve to a CGFloat based on current appearance mode
        var resolvedValue: CGFloat? {
            resolvedValue(isDark: UIScreen.isDarkModeEnabled)
        }

        init?(
            colored: CGFloat? = 0,
            light: CGFloat? = 0,
            dark: CGFloat? = 0
        ) {
            self.colored = colored
            self.light = light
            self.dark = dark
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            colored = (try? container.decode(CGFloat?.self, forKey: .colored)) ?? nil
            light = (try? container.decode(CGFloat?.self, forKey: .light)) ?? nil
            dark = (try? container.decode(CGFloat?.self, forKey: .dark)) ?? nil
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(colored, forKey: .colored)
            try? container.encode(light, forKey: .light)
            try? container.encode(dark, forKey: .dark)
        }

        func resolvedValue(isDark: Bool) -> CGFloat? {
            schemeVariant(isDark: isDark, colored: colored, light: light, dark: dark)
        }
    }
}

// MARK: - Helper Extensions

private func schemeVariant<T>(isDark: Bool, colored: T?, light: T?, dark: T?) -> T? {
    isDark ? (dark ?? colored ?? light) : (colored ?? light ?? dark)
}

extension String {
    /// Convert hex string to UIColor
    func hexToUIColor() -> UIColor? {
        var hexString = trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove # prefix if present
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        // Ensure valid length
        guard hexString.count == 6 else { return nil }

        // Parse RGB components
        var rgb: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&rgb) else { return nil }

        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
