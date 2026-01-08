//
//  DesignTokensManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

@available(iOS 15.0, *)
final class DesignTokensManager: ObservableObject {
    @Published var tokens: DesignTokens?
    private var themeOverrides: PrimerCheckoutTheme?

    // MARK: - Theme Override API

    func applyTheme(_ theme: PrimerCheckoutTheme) {
        self.themeOverrides = theme
    }

    // Merchant overrides take precedence over internal tokens
    func color(
        _ keyPath: KeyPath<DesignTokens, [CGFloat]>,
        override overrideKeyPath: KeyPath<ColorOverrides, Color?>? = nil
    ) -> Color {
        // Check merchant override first
        if let overrideKeyPath,
           let colorOverrides = themeOverrides?.colors,
           let overrideColor = colorOverrides[keyPath: overrideKeyPath] {
            return overrideColor
        }

        // Fall back to internal tokens
        guard let tokens else { return .clear }
        let rgba = tokens[keyPath: keyPath]
        return Color(red: rgba[0], green: rgba[1], blue: rgba[2], opacity: rgba[3])
    }

    func radius(_ keyPath: KeyPath<DesignTokens, CGFloat>, override overrideKeyPath: KeyPath<RadiusOverrides, CGFloat?>? = nil) -> CGFloat {
        if let overrideKeyPath,
           let radiusOverrides = themeOverrides?.radius,
           let overrideValue = radiusOverrides[keyPath: overrideKeyPath] {
            return overrideValue
        }
        return tokens?[keyPath: keyPath] ?? 0
    }

    func spacing(_ keyPath: KeyPath<DesignTokens, CGFloat>, override overrideKeyPath: KeyPath<SpacingOverrides, CGFloat?>? = nil) -> CGFloat {
        if let overrideKeyPath,
           let spacingOverrides = themeOverrides?.spacing,
           let overrideValue = spacingOverrides[keyPath: overrideKeyPath] {
            return overrideValue
        }
        return tokens?[keyPath: keyPath] ?? 0
    }

    func size(_ keyPath: KeyPath<DesignTokens, CGFloat>, override overrideKeyPath: KeyPath<SizeOverrides, CGFloat?>? = nil) -> CGFloat {
        if let overrideKeyPath,
           let sizeOverrides = themeOverrides?.sizes,
           let overrideValue = sizeOverrides[keyPath: overrideKeyPath] {
            return overrideValue
        }
        return tokens?[keyPath: keyPath] ?? 0
    }

    /// Returns a border width value, checking merchant overrides first, then internal tokens.
    func borderWidth(
        _ keyPath: KeyPath<DesignTokens, CGFloat>,
        override overrideKeyPath: KeyPath<BorderWidthOverrides, CGFloat?>? = nil
    ) -> CGFloat {
        if let overrideKeyPath,
           let borderWidthOverrides = themeOverrides?.borderWidth,
           let overrideValue = borderWidthOverrides[keyPath: overrideKeyPath] {
            return overrideValue
        }
        return tokens?[keyPath: keyPath] ?? 1
    }

    /// Returns a typography style, checking merchant overrides first.
    /// - Parameter overrideKeyPath: Key path to the merchant override typography property
    /// - Returns: The typography style from merchant override if set, otherwise nil
    func typography(override overrideKeyPath: KeyPath<TypographyOverrides, TypographyOverrides.TypographyStyle?>?) -> TypographyOverrides.TypographyStyle? {
        guard let overrideKeyPath,
              let typographyOverrides = themeOverrides?.typography else {
            return nil
        }
        return typographyOverrides[keyPath: overrideKeyPath]
    }

    /// Creates a Font using typography overrides or defaults.
    /// - Parameters:
    ///   - overrideKeyPath: Key path to the merchant override typography property
    ///   - defaultSize: Default font size if no override is set
    ///   - defaultWeight: Default font weight if no override is set
    /// - Returns: A configured Font
    func font(
        override overrideKeyPath: KeyPath<TypographyOverrides, TypographyOverrides.TypographyStyle?>?,
        defaultSize: CGFloat,
        defaultWeight: Font.Weight = .regular
    ) -> Font {
        let style = typography(override: overrideKeyPath)
        let size = style?.size ?? defaultSize
        let weight = style?.weight ?? defaultWeight

        if let fontName = style?.font {
            return Font.custom(fontName, size: size).weight(weight)
        }
        return Font.system(size: size, weight: weight)
    }

    // MARK: - Token Loading

    func fetchTokens(for colorScheme: ColorScheme) async throws {
        // Load and merge tokens
        let baseDict = try loadJSON(named: "base")
        let mergedDict = colorScheme == .dark
            ? DesignTokensProcessor.mergeDictionaries(baseDict, with: try loadJSON(named: "dark"))
            : baseDict

        // Process tokens through transformation pipeline
        var processedDict = DesignTokensProcessor.resolveReferences(in: mergedDict)
        processedDict = DesignTokensProcessor.convertHexColors(in: processedDict)
        var flatDict = DesignTokensProcessor.flattenTokenDictionary(processedDict)
        flatDict = DesignTokensProcessor.resolveFlattenedReferences(in: flatDict, source: processedDict)
        flatDict = DesignTokensProcessor.evaluateMath(in: flatDict)

        // Decode tokens from JSON
        let data = try JSONSerialization.data(withJSONObject: flatDict)
        let loadedTokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Apply merchant theme overrides on top of loaded tokens
        let finalTokens = applyThemeOverrides(to: loadedTokens)

        await MainActor.run {
            self.tokens = finalTokens
        }
    }

    // MARK: - Apply Theme Overrides

    /// Applies merchant theme overrides to the loaded design tokens.
    /// This ensures that CheckoutColors and other direct token accessors respect theme customizations.
    private func applyThemeOverrides(to tokens: DesignTokens) -> DesignTokens {
        guard let theme = themeOverrides else { return tokens }

        if let colors = theme.colors {
            applyColorOverrides(to: tokens, from: colors)
        }
        if let radius = theme.radius {
            applyRadiusOverrides(to: tokens, from: radius)
        }
        if let spacing = theme.spacing {
            applySpacingOverrides(to: tokens, from: spacing)
        }
        if let sizes = theme.sizes {
            applySizeOverrides(to: tokens, from: sizes)
        }
        if let typography = theme.typography {
            applyTypographyOverrides(to: tokens, from: typography)
        }

        return tokens
    }

    private func applyColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
        applyBrandAndGrayColorOverrides(to: tokens, from: colors)
        applySemanticColorOverrides(to: tokens, from: colors)
        applyTextColorOverrides(to: tokens, from: colors)
        applyBorderColorOverrides(to: tokens, from: colors)
        applyIconAndOtherColorOverrides(to: tokens, from: colors)
    }

    private func applyBrandAndGrayColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
        if let value = colors.primerColorBrand { tokens.primerColorBrand = value }
        if let value = colors.primerColorGray000 { tokens.primerColorGray000 = value }
        if let value = colors.primerColorGray100 { tokens.primerColorGray100 = value }
        if let value = colors.primerColorGray200 { tokens.primerColorGray200 = value }
        if let value = colors.primerColorGray300 { tokens.primerColorGray300 = value }
        if let value = colors.primerColorGray400 { tokens.primerColorGray400 = value }
        if let value = colors.primerColorGray500 { tokens.primerColorGray500 = value }
        if let value = colors.primerColorGray600 { tokens.primerColorGray600 = value }
        if let value = colors.primerColorGray700 { tokens.primerColorGray700 = value }
        if let value = colors.primerColorGray900 { tokens.primerColorGray900 = value }
    }

    private func applySemanticColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
        if let value = colors.primerColorGreen500 { tokens.primerColorGreen500 = value }
        if let value = colors.primerColorRed100 { tokens.primerColorRed100 = value }
        if let value = colors.primerColorRed500 { tokens.primerColorRed500 = value }
        if let value = colors.primerColorRed900 { tokens.primerColorRed900 = value }
        if let value = colors.primerColorBlue500 { tokens.primerColorBlue500 = value }
        if let value = colors.primerColorBlue900 { tokens.primerColorBlue900 = value }
        if let value = colors.primerColorBackground { tokens.primerColorBackground = value }
    }

    private func applyTextColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
        if let value = colors.primerColorTextPrimary { tokens.primerColorTextPrimary = value }
        if let value = colors.primerColorTextSecondary { tokens.primerColorTextSecondary = value }
        if let value = colors.primerColorTextPlaceholder { tokens.primerColorTextPlaceholder = value }
        if let value = colors.primerColorTextDisabled { tokens.primerColorTextDisabled = value }
        if let value = colors.primerColorTextNegative { tokens.primerColorTextNegative = value }
        if let value = colors.primerColorTextLink { tokens.primerColorTextLink = value }
    }

    private func applyBorderColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
        applyOutlinedBorderColorOverrides(to: tokens, from: colors)
        applyTransparentBorderColorOverrides(to: tokens, from: colors)
    }

    private func applyOutlinedBorderColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
        if let value = colors.primerColorBorderOutlinedDefault { tokens.primerColorBorderOutlinedDefault = value }
        if let value = colors.primerColorBorderOutlinedHover { tokens.primerColorBorderOutlinedHover = value }
        if let value = colors.primerColorBorderOutlinedActive { tokens.primerColorBorderOutlinedActive = value }
        if let value = colors.primerColorBorderOutlinedFocus { tokens.primerColorBorderOutlinedFocus = value }
        if let value = colors.primerColorBorderOutlinedDisabled { tokens.primerColorBorderOutlinedDisabled = value }
        if let value = colors.primerColorBorderOutlinedError { tokens.primerColorBorderOutlinedError = value }
        if let value = colors.primerColorBorderOutlinedSelected { tokens.primerColorBorderOutlinedSelected = value }
        if let value = colors.primerColorBorderOutlinedLoading { tokens.primerColorBorderOutlinedLoading = value }
    }

    private func applyTransparentBorderColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
        if let value = colors.primerColorBorderTransparentDefault { tokens.primerColorBorderTransparentDefault = value }
        if let value = colors.primerColorBorderTransparentHover { tokens.primerColorBorderTransparentHover = value }
        if let value = colors.primerColorBorderTransparentActive { tokens.primerColorBorderTransparentActive = value }
        if let value = colors.primerColorBorderTransparentFocus { tokens.primerColorBorderTransparentFocus = value }
        if let value = colors.primerColorBorderTransparentDisabled { tokens.primerColorBorderTransparentDisabled = value }
        if let value = colors.primerColorBorderTransparentSelected { tokens.primerColorBorderTransparentSelected = value }
    }

    private func applyIconAndOtherColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
        if let value = colors.primerColorIconPrimary { tokens.primerColorIconPrimary = value }
        if let value = colors.primerColorIconDisabled { tokens.primerColorIconDisabled = value }
        if let value = colors.primerColorIconNegative { tokens.primerColorIconNegative = value }
        if let value = colors.primerColorIconPositive { tokens.primerColorIconPositive = value }
        if let value = colors.primerColorFocus { tokens.primerColorFocus = value }
        if let value = colors.primerColorLoader { tokens.primerColorLoader = value }
    }

    private func applyRadiusOverrides(to tokens: DesignTokens, from radius: RadiusOverrides) {
        if let value = radius.primerRadiusXsmall { tokens.primerRadiusXsmall = value }
        if let value = radius.primerRadiusSmall { tokens.primerRadiusSmall = value }
        if let value = radius.primerRadiusMedium { tokens.primerRadiusMedium = value }
        if let value = radius.primerRadiusLarge { tokens.primerRadiusLarge = value }
        if let value = radius.primerRadiusBase { tokens.primerRadiusBase = value }
    }

    private func applySpacingOverrides(to tokens: DesignTokens, from spacing: SpacingOverrides) {
        if let value = spacing.primerSpaceXxsmall { tokens.primerSpaceXxsmall = value }
        if let value = spacing.primerSpaceXsmall { tokens.primerSpaceXsmall = value }
        if let value = spacing.primerSpaceSmall { tokens.primerSpaceSmall = value }
        if let value = spacing.primerSpaceMedium { tokens.primerSpaceMedium = value }
        if let value = spacing.primerSpaceLarge { tokens.primerSpaceLarge = value }
        if let value = spacing.primerSpaceXlarge { tokens.primerSpaceXlarge = value }
        if let value = spacing.primerSpaceXxlarge { tokens.primerSpaceXxlarge = value }
        if let value = spacing.primerSpaceBase { tokens.primerSpaceBase = value }
    }

    private func applySizeOverrides(to tokens: DesignTokens, from sizes: SizeOverrides) {
        if let value = sizes.primerSizeSmall { tokens.primerSizeSmall = value }
        if let value = sizes.primerSizeMedium { tokens.primerSizeMedium = value }
        if let value = sizes.primerSizeLarge { tokens.primerSizeLarge = value }
        if let value = sizes.primerSizeXlarge { tokens.primerSizeXlarge = value }
        if let value = sizes.primerSizeXxlarge { tokens.primerSizeXxlarge = value }
        if let value = sizes.primerSizeXxxlarge { tokens.primerSizeXxxlarge = value }
        if let value = sizes.primerSizeBase { tokens.primerSizeBase = value }
    }

    private func applyTypographyOverrides(to tokens: DesignTokens, from typography: TypographyOverrides) {
        // Title XLarge
        if let style = typography.titleXlarge {
            if let font = style.font { tokens.primerTypographyTitleXlargeFont = font }
            if let size = style.size { tokens.primerTypographyTitleXlargeSize = size }
            if let weight = style.weight { tokens.primerTypographyTitleXlargeWeight = fontWeightToCGFloat(weight) }
            if let letterSpacing = style.letterSpacing { tokens.primerTypographyTitleXlargeLetterSpacing = letterSpacing }
            if let lineHeight = style.lineHeight { tokens.primerTypographyTitleXlargeLineHeight = lineHeight }
        }

        // Title Large
        if let style = typography.titleLarge {
            if let font = style.font { tokens.primerTypographyTitleLargeFont = font }
            if let size = style.size { tokens.primerTypographyTitleLargeSize = size }
            if let weight = style.weight { tokens.primerTypographyTitleLargeWeight = fontWeightToCGFloat(weight) }
            if let letterSpacing = style.letterSpacing { tokens.primerTypographyTitleLargeLetterSpacing = letterSpacing }
            if let lineHeight = style.lineHeight { tokens.primerTypographyTitleLargeLineHeight = lineHeight }
        }

        // Body Large
        if let style = typography.bodyLarge {
            if let font = style.font { tokens.primerTypographyBodyLargeFont = font }
            if let size = style.size { tokens.primerTypographyBodyLargeSize = size }
            if let weight = style.weight { tokens.primerTypographyBodyLargeWeight = fontWeightToCGFloat(weight) }
            if let letterSpacing = style.letterSpacing { tokens.primerTypographyBodyLargeLetterSpacing = letterSpacing }
            if let lineHeight = style.lineHeight { tokens.primerTypographyBodyLargeLineHeight = lineHeight }
        }

        // Body Medium
        if let style = typography.bodyMedium {
            if let font = style.font { tokens.primerTypographyBodyMediumFont = font }
            if let size = style.size { tokens.primerTypographyBodyMediumSize = size }
            if let weight = style.weight { tokens.primerTypographyBodyMediumWeight = fontWeightToCGFloat(weight) }
            if let letterSpacing = style.letterSpacing { tokens.primerTypographyBodyMediumLetterSpacing = letterSpacing }
            if let lineHeight = style.lineHeight { tokens.primerTypographyBodyMediumLineHeight = lineHeight }
        }

        // Body Small
        if let style = typography.bodySmall {
            if let font = style.font { tokens.primerTypographyBodySmallFont = font }
            if let size = style.size { tokens.primerTypographyBodySmallSize = size }
            if let weight = style.weight { tokens.primerTypographyBodySmallWeight = fontWeightToCGFloat(weight) }
            if let letterSpacing = style.letterSpacing { tokens.primerTypographyBodySmallLetterSpacing = letterSpacing }
            if let lineHeight = style.lineHeight { tokens.primerTypographyBodySmallLineHeight = lineHeight }
        }
    }

    private func fontWeightToCGFloat(_ weight: Font.Weight) -> CGFloat {
        switch weight {
        case .ultraLight: return 100
        case .thin: return 200
        case .light: return 300
        case .regular: return 400
        case .medium: return 500
        case .semibold: return 600
        case .bold: return 700
        case .heavy: return 800
        case .black: return 900
        default: return 400
        }
    }

    // MARK: - JSON Loading

    private func loadJSON(named fileName: String) throws -> [String: Any] {
        guard let url = Bundle.primerResources.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PrimerError.failedToLoadDesignTokens(fileName: fileName)
        }
        return dictionary
    }

    // MARK: - Dictionary Operations

    private func mergeDictionaries(_ base: [String: Any], with override: [String: Any]) -> [String: Any] {
        var merged = base
        for (key, overrideValue) in override {
            if let baseDict = base[key] as? [String: Any],
               let overrideDict = overrideValue as? [String: Any] {
                merged[key] = mergeDictionaries(baseDict, with: overrideDict)
            } else {
                merged[key] = overrideValue
            }
        }
        return merged
    }

    // MARK: - Token Reference Resolution

    private func resolveReferences(in dict: [String: Any]) -> [String: Any] {
        (0..<10).reduce(dict) { current, _ in
            var hasUnresolved = false
            let resolved = resolvePass(current, root: current, hasUnresolved: &hasUnresolved)
            return hasUnresolved ? resolved : current
        }
    }

    private func resolvePass(_ dict: [String: Any], root: [String: Any], hasUnresolved: inout Bool) -> [String: Any] {
        dict.reduce(into: [String: Any]()) { result, pair in
            let (key, value) = pair
            if let nested = value as? [String: Any] {
                result[key] = resolvePass(nested, root: root, hasUnresolved: &hasUnresolved)
            } else if let ref = value as? String, ref.hasPrefix("{"), ref.hasSuffix("}") {
                let reference = String(ref.dropFirst().dropLast())
                if let resolved = resolveReference(reference, in: root) {
                    result[key] = resolved
                } else {
                    result[key] = value
                    hasUnresolved = true
                }
            } else {
                result[key] = value
            }
        }
    }

    private func resolveReference(_ reference: String, in root: [String: Any]) -> Any? {
        let parts = reference.split(separator: ".").map(String.init)
        var current: Any = root

        for part in parts {
            guard let dict = current as? [String: Any], let next = dict[part] else {
                return nil
            }
            current = next
        }

        // Return nil if still a reference (needs another pass)
        if let str = current as? String, str.hasPrefix("{"), str.hasSuffix("}") {
            return nil
        }

        // Extract value from nested structure and convert hex colors
        if let dict = current as? [String: Any], let value = dict["value"] {
            if let hex = value as? String, hex.hasPrefix("#"), let colorArray = hexToColorArray(hex) {
                return colorArray
            }
            return value
        }

        return current
    }

    // MARK: - Hex Color Conversion

    private func convertHexColors(in dict: [String: Any]) -> [String: Any] {
        dict.reduce(into: [String: Any]()) { result, pair in
            let (key, value) = pair
            if let nested = value as? [String: Any] {
                result[key] = convertHexColors(in: nested)
            } else if let hex = value as? String, hex.hasPrefix("#"), let colorArray = hexToColorArray(hex) {
                result[key] = colorArray
            } else {
                result[key] = value
            }
        }
    }

    private func hexToColorArray(_ hex: String) -> [CGFloat]? {
        let sanitized = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&rgb) else { return nil }

        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        var alpha: CGFloat

        if sanitized.count == 8 { // RRGGBBAA
            red = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            green = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            blue = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            alpha = CGFloat(rgb & 0x000000FF) / 255.0
        } else if sanitized.count == 6 { // RRGGBB
            red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(rgb & 0x0000FF) / 255.0
            alpha = 1.0
        } else {
            return nil
        }

        return [red, green, blue, alpha]
    }

    // MARK: - Dictionary Flattening

    private func flattenTokenDictionary(_ dict: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        flattenRecursive(dict, prefix: "", result: &result)
        return result
    }

    private func flattenRecursive(_ dict: [String: Any], prefix: String, result: inout [String: Any]) {
        for (key, value) in dict {
            let path = prefix.isEmpty ? key : "\(prefix).\(key)"

            if let nested = value as? [String: Any] {
                if let actualValue = nested["value"] {
                    result[toCamelCase(path)] = actualValue
                } else {
                    flattenRecursive(nested, prefix: path, result: &result)
                }
            } else {
                result[toCamelCase(path)] = value
            }
        }
    }

    private func toCamelCase(_ path: String) -> String {
        let parts = path.split(separator: ".").map(String.init)
        return parts.enumerated().map { index, part in
            index == 0 ? part : part.prefix(1).uppercased() + part.dropFirst()
        }.joined()
    }

    private func resolveFlattenedReferences(in flatDict: [String: Any], source: [String: Any]) -> [String: Any] {
        (0..<10).reduce(flatDict) { current, _ in
            var hasUnresolved = false
            let resolved = current.reduce(into: [String: Any]()) { result, pair in
                let (key, value) = pair
                guard let str = value as? String, str.contains("{"), str.contains("}") else {
                    result[key] = value
                    return
                }

                result[key] = resolveReferencesInString(str, flatDict: current, source: source, hasUnresolved: &hasUnresolved)
            }
            return resolved
        }
    }

    private func resolveReferencesInString(_ string: String, flatDict: [String: Any], source: [String: Any], hasUnresolved: inout Bool) -> Any {
        guard let regex = try? NSRegularExpression(pattern: "\\{([^}]+)\\}") else { return string }

        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        var result: Any = string

        for match in matches.reversed() {
            guard let range = Range(match.range(at: 1), in: string) else { continue }
            let reference = String(string[range])
            let flatKey = toCamelCase(reference)

            // If entire string is just a reference, return the resolved value directly
            if string == "{\(reference)}" {
                if let resolved = flatDict[flatKey] ?? resolveReference(reference, in: source) {
                    return resolved
                }
                hasUnresolved = true
                return string
            }

            // Otherwise, replace reference in string
            if let resolved = flatDict[flatKey] ?? resolveReference(reference, in: source),
               var stringResult = result as? String,
               let fullRange = Range(match.range, in: stringResult) {
                stringResult.replaceSubrange(fullRange, with: "\(resolved)")
                result = stringResult
            } else {
                hasUnresolved = true
            }
        }

        return result
    }

    // MARK: - Math Expression Evaluation

    private func evaluateMath(in dict: [String: Any]) -> [String: Any] {
        dict.reduce(into: [String: Any]()) { result, pair in
            let (key, value) = pair
            if let str = value as? String, let evaluated = evaluateExpression(str) {
                result[key] = evaluated
            } else {
                result[key] = value
            }
        }
    }

    private func evaluateExpression(_ expression: String) -> Double? {
        let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        let operators: [(Character, (Double, Double) -> Double)] = [
            ("*", (*)), ("/", (/)), ("+", (+)), ("-", (-))
        ]

        for (op, operation) in operators {
            guard let index = trimmed.firstIndex(of: op) else { continue }
            let left = trimmed[..<index].trimmingCharacters(in: .whitespaces)
            let right = trimmed[trimmed.index(after: index)...].trimmingCharacters(in: .whitespaces)

            if let leftVal = Double(left), let rightVal = Double(right) {
                return op == "/" && rightVal == 0 ? nil : operation(leftVal, rightVal)
            }
        }

        return nil
    }
}
