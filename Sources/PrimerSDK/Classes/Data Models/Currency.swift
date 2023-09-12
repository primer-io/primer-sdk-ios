

internal struct CurrencyElement: Codable {
    let name: String
    let symbol: String
    let symbolNative: String
    let code: Currency
    let namePlural: String
    let decimalDigits: Int
    let rounding: Double
}

internal var loadedCurrencies: [CurrencyElement]? = {
    let jsonParser = JSONParser()
    guard let currenciesData = jsonParser.loadJsonData(fileName: "currencies") else {
        return nil
    }
    return try? jsonParser.parse([CurrencyElement].self, from: currenciesData)
}()

public enum Currency: String, Codable, CaseIterable {
    case AED
    case AFN
    case ALL
    case AMD
    case ANG
    case AOA
    case ARS
    case AUD
    case AWG
    case AZN
    case BAM
    case BBD
    case BDT
    case BGN
    case BHD
    case BIF
    case BMD
    case BND
    case BOB
    case BRL
    case BSD
    case BTN
    case BWP
    case BYN
    case BZD
    case CAD
    case CDF
    case CHF
    case CKD
    case CLP
    case CNY
    case COP
    case CRC
    case CUC
    case CUP
    case CVE
    case CZK
    case DJF
    case DKK
    case DOP
    case DZD
    case EEK
    case EGP
    case ERN
    case ETB
    case EUR
    case FJD
    case FKP
    case FOK
    case GBP
    case GEL
    case GGP
    case GHS
    case GIP
    case GMD
    case GNF
    case GTQ
    case GYD
    case HKD
    case HNL
    case HRK
    case HTG
    case HUF
    case IDR
    case ILS
    case IMP
    case INR
    case IQD
    case IRR
    case ISK
    case JEP
    case JMD
    case JOD
    case JPY
    case KES
    case KGS
    case KHR
    case KID
    case KMF
    case KPW
    case KRW
    case KWD
    case KYD
    case KZT
    case LAK
    case LBP
    case LKR
    case LRD
    case LSL
    case LTL
    case LVL
    case LYD
    case MAD
    case MDL
    case MGA
    case MKD
    case MMK
    case MNT
    case MOP
    case MRU
    case MUR
    case MVR
    case MWK
    case MXN
    case MYR
    case MZN
    case NAD
    case NGN
    case NIO
    case NOK
    case NPR
    case NZD
    case OMR
    case PAB
    case PEN
    case PGK
    case PHP
    case PKR
    case PLN
    case PND
    case PRB
    case PYG
    case QAR
    case RON
    case RSD
    case RUB
    case RWF
    case SAR
    case SBD
    case SCR
    case SDG
    case SEK
    case SGD
    case SHP
    case SLL
    case SLS
    case SOS
    case SRD
    case SSP
    case STN
    case SYP
    case SZL
    case THB
    case TJS
    case TMT
    case TND
    case TOP
    case TRY
    case TTD
    case TVD
    case TWD
    case TZS
    case UAH
    case UGX
    case USD
    case UYU
    case UZS
    case VEF
    case VES
    case VND
    case VUV
    case WST
    case XAF
    case XCD
    case XOF
    case XPF
    case YER
    case ZAR
    case ZMK
    case ZMW
    case ZWL
    
    var currencyElement: CurrencyElement? {
        loadedCurrencies?.first{ $0.code == self }
    }

    var symbol: String? {
        return currencyElement?.symbolNative
    }
    
    var isZeroDecimal: Bool {
        return currencyElement?.decimalDigits == 0
    }
}


