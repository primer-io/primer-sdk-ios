public enum Currency: String, Codable {
    case USD
    case GBP
    case EUR
    case SEK
    case NOK
    case DKK
    case JPY
    case AUD
    case CAD
    case CHF
    case CNY
    case HKD
    case NZD
    case KRW
    case SGD
    case MXN
    case INR
    case RUB
    case ZAR
    case TRY
    case BRL
    case TWD
    case PLN
    case THB
    case IDR
    case HUF
    case CZK
    case ILS
    case CLP
    case AED
    case COP
    case SAR
    case MYR
    case RON
}

extension Currency {
    func withSymbol(for value: String) -> String {
        switch self {
        case .USD:
            return "$\(value)"
        case .GBP:
            return "£\(value)"
        case .EUR:
            return "€\(value)"
        case .JPY:
            return "¥\(value)"
        case .KRW:
            return "₩\(value)"
        default:
            return "\(value) \(self.rawValue)"
        }
    }

    var isZeroDecimal: Bool {
        switch self {
        case .JPY, .KRW, .CLP:
            return true
        default:
            return false
        }
    }

    func format(value: Double) -> String {
        if (isZeroDecimal) {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}
