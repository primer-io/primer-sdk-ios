import Foundation

/// Utility class for processing design token dictionaries.
/// Provides static methods for merging, reference resolution, color conversion,
/// flattening, and math expression evaluation.
enum DesignTokensProcessor {

    // MARK: - Dictionary Operations

    static func mergeDictionaries(_ base: [String: Any], with override: [String: Any]) -> [String: Any] {
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

    static func resolveReferences(in dict: [String: Any]) -> [String: Any] {
        (0..<10).reduce(dict) { current, _ in
            var hasUnresolved = false
            let resolved = resolvePass(current, root: current, hasUnresolved: &hasUnresolved)
            return hasUnresolved ? resolved : current
        }
    }

    private static func resolvePass(_ dict: [String: Any], root: [String: Any], hasUnresolved: inout Bool) -> [String: Any] {
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

    private static func resolveReference(_ reference: String, in root: [String: Any]) -> Any? {
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
        guard let dict = current as? [String: Any], let value = dict["value"] else {
            return current
        }

        if let hex = value as? String, hex.hasPrefix("#"), let colorArray = hexToColorArray(hex) {
            return colorArray
        }

        return value
    }

    // MARK: - Hex Color Conversion

    static func convertHexColors(in dict: [String: Any]) -> [String: Any] {
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

    private static func hexToColorArray(_ hex: String) -> [CGFloat]? {
        let sanitized = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&rgb) else { return nil }

        let (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat)
        if sanitized.count == 8 { // RRGGBBAA
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else if sanitized.count == 6 { // RRGGBB
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else {
            return nil
        }

        return [r, g, b, a]
    }

    // MARK: - Dictionary Flattening

    static func flattenTokenDictionary(_ dict: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        flattenRecursive(dict, prefix: "", result: &result)
        return result
    }

    private static func flattenRecursive(_ dict: [String: Any], prefix: String, result: inout [String: Any]) {
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

    private static func toCamelCase(_ path: String) -> String {
        let parts = path.split(separator: ".").map(String.init)
        return parts.enumerated().map { index, part in
            index == 0 ? part : part.prefix(1).uppercased() + part.dropFirst()
        }.joined()
    }

    static func resolveFlattenedReferences(in flatDict: [String: Any], source: [String: Any]) -> [String: Any] {
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

    private static func resolveReferencesInString(_ string: String, flatDict: [String: Any], source: [String: Any], hasUnresolved: inout Bool) -> Any {
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

    static func evaluateMath(in dict: [String: Any]) -> [String: Any] {
        dict.reduce(into: [String: Any]()) { result, pair in
            let (key, value) = pair
            if let str = value as? String, let evaluated = evaluateExpression(str) {
                result[key] = evaluated
            } else {
                result[key] = value
            }
        }
    }

    private static func evaluateExpression(_ expression: String) -> Double? {
        let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        let operators: [(Character, (Double, Double) -> Double)] = [
            ("*", *), ("/", /), ("+", +), ("-", -)
        ]

        for (symbol, operation) in operators {
            guard let index = trimmed.firstIndex(of: symbol) else { continue }
            let left = trimmed[..<index].trimmingCharacters(in: .whitespaces)
            let right = trimmed[trimmed.index(after: index)...].trimmingCharacters(in: .whitespaces)

            if let leftVal = Double(left), let rightVal = Double(right) {
                return symbol == "/" && rightVal == 0 ? nil : operation(leftVal, rightVal)
            }
        }

        return nil
    }
}
