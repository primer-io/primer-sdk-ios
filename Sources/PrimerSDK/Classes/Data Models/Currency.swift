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
    var symbol: String? {
        switch self {
        case .USD:
            return "$"
        case .GBP:
            return "£"
        case .EUR:
            return "€"
        case .JPY:
            return "¥"
        case .KRW:
            return "₩"
        default:
            return nil
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
        
}
