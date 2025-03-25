import UIKit

@objc
public enum PrimerInputElementType: Int {
    // Existing cases
    case cardNumber
    case expiryDate
    case cvv
    case cardholderName
    case otp
    case postalCode
    case phoneNumber
    case retailer
    case unknown
    case countryCode
    case firstName
    case lastName
    case addressLine1
    case addressLine2
    case city
    case state
    case all // General case for "all fields"

    public var stringValue: String {
        switch self {
        // Existing cases
        case .cardNumber:
            return "CARD_NUMBER"
        case .expiryDate:
            return "EXPIRY_DATE"
        case .cvv:
            return "CVV"
        case .cardholderName:
            return "CARDHOLDER_NAME"
        case .otp:
            return "OTP"
        case .postalCode:
            return "POSTAL_CODE"
        case .phoneNumber:
            return "PHONE_NUMBER"
        case .retailer:
            return "RETAILER"
        case .unknown:
            return "UNKNOWN"
        // New cases
        case .countryCode:
            return "COUNTRY_CODE"
        case .firstName:
            return "FIRST_NAME"
        case .lastName:
            return "LAST_NAME"
        case .addressLine1:
            return "ADDRESS_LINE_1"
        case .addressLine2:
            return "ADDRESS_LINE_2"
        case .city:
            return "CITY"
        case .state:
            return "STATE"
        case .all:
            return "ALL"
        }
    }

    /// Refactored validation method with reduced cyclomatic complexity.
    internal func validate(value: Any, detectedValueType: Any?) -> Bool {
        // For .all and .retailer, no validation is needed.
        if self == .all || self == .retailer {
            return true
        }
        // .unknown always fails validation.
        if self == .unknown {
            return false
        }

        // Attempt to cast the input value to a String for the remaining cases.
        guard let text = value as? String else { return false }

        switch self {
        case .cardNumber:
            return text.isValidCardNumber
        case .expiryDate:
            return text.isValidExpiryDate
        case .cvv:
            // Validate using CardNetwork if available, otherwise check length.
            if let cardNetwork = detectedValueType as? CardNetwork, cardNetwork != .unknown {
                return text.isValidCVV(cardNetwork: cardNetwork)
            }
            return text.count >= 3 && text.count <= 5
        case .cardholderName:
            return text.isValidNonDecimalString
        case .otp:
            return text.isNumeric
        case .postalCode:
            return text.isValidPostalCode
        case .phoneNumber:
            return text.isNumeric
        case .countryCode:
            return !text.isEmpty
        case .firstName, .lastName:
            return text.isValidNonDecimalString
        case .addressLine1, .addressLine2, .city, .state:
            return !text.isEmpty
        default:
            // In case additional cases are added later.
            return false
        }
    }

    // MARK: - Additional Methods

    internal func format(value: Any) -> Any {
        switch self {
        case .cardNumber:
            guard let text = value as? String, let delimiter = self.delimiter else { return value }
            return text.withoutWhiteSpace.separate(every: 4, with: delimiter)
        case .expiryDate:
            guard let text = value as? String, let delimiter = self.delimiter else { return value }
            return text.withoutWhiteSpace.separate(every: 2, with: delimiter)
        default:
            return value
        }
    }

    internal func clearFormatting(value: Any) -> Any? {
        switch self {
        case .cardNumber, .expiryDate:
            guard let text = value as? String, let delimiter = self.delimiter else { return nil }
            let textWithoutWhiteSpace = text.withoutWhiteSpace
            return textWithoutWhiteSpace.replacingOccurrences(of: delimiter, with: "")
        default:
            return value
        }
    }

    internal func detectType(for value: Any) -> Any? {
        switch self {
        case .cardNumber:
            guard let text = value as? String else { return nil }
            return CardNetwork(cardNumber: text)
        default:
            return value
        }
    }

    internal var delimiter: String? {
        switch self {
        case .cardNumber:
            return " "
        case .expiryDate:
            return "/"
        default:
            return nil
        }
    }

    internal var maxAllowedLength: Int? {
        switch self {
        case .cardNumber:
            return nil
        case .expiryDate:
            return 4
        case .cvv:
            return nil
        case .postalCode:
            return 10
        default:
            return nil
        }
    }

    internal var allowedCharacterSet: CharacterSet? {
        switch self {
        case .cardNumber, .expiryDate, .cvv, .otp, .phoneNumber:
            return CharacterSet(charactersIn: "0123456789")
        case .cardholderName, .firstName, .lastName:
            return CharacterSet.letters.union(.whitespaces)
        default:
            return nil
        }
    }

    internal var keyboardType: UIKeyboardType {
        switch self {
        case .cardNumber, .expiryDate, .cvv, .otp, .phoneNumber, .postalCode:
            return UIKeyboardType.numberPad
        case .cardholderName, .firstName, .lastName, .city, .state:
            return UIKeyboardType.alphabet
        case .addressLine1, .addressLine2, .countryCode, .retailer, .unknown, .all:
            return UIKeyboardType.default
        }
    }
}
