import Foundation

internal class Mask {

    enum CharType {
        case digit, any
        case symbol(Character)

        init(fromCharacter char: Character) {
            if char == "#" {
                self = .digit
            } else if char == "*" {
                self = .any
            } else {
                self = .symbol(char)
            }
        }

        public func write(_ char: Character) -> (Bool, String) {
            let charString = String(char)
            let isInt = Int(charString) != nil
            switch self {
            case .digit: return (isInt, isInt ? charString : "")
            case .any: return (true, charString)
            case .symbol(let symbol): return (char == symbol, String(symbol))
            }
        }

        public func read(_ char: Character) -> (Bool, String) {
            let charString = String(char)
            let isInt = Int(charString) != nil
            switch self {
            case .digit: return (isInt, isInt ? charString : "")
            case .any: return (true, charString)
            case .symbol(let symbol): return (char == symbol, "")
            }
        }
    }

    let pattern: [CharType]

    init(pattern: [CharType]) { self.pattern = pattern }

    public convenience init(pattern string: String) {
        let pattern = Self.stringToChars(string).map { CharType(fromCharacter: $0) }
        self.init(pattern: pattern)
    }

    public func apply(on input: String) -> String { Self.apply(on: input, with: pattern) }

    static func stringToChars(_ string: String) -> [Character] { return Array(string) }

    static func apply(on input: String, with pattern: [CharType]) -> String {
        Self.process(input: input, pattern: pattern).masked
    }

    static func process(input: String, pattern: [CharType]) -> (masked: String, unmasked: String) {
        guard let charType = pattern.first else { return ("", "") }
        guard let inputChar = input.first else { return ("", "") }

        let inputRemaining = Array(input).suffix(from: 1)
        let tokensRemaining = Array(pattern.suffix(from: 1))

        let (matches, output) = charType.write(inputChar)
        let (_, pureInput) = charType.read(inputChar)

        let result = process(input: matches ? String(inputRemaining) : input, pattern: tokensRemaining)
        return (output + result.masked, pureInput + result.unmasked)
    }
}
