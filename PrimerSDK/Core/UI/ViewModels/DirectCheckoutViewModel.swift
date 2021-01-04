protocol DirectCheckoutViewModelProtocol {
    var amountViewModel: AmountViewModel { get }
    var paymentMethods: [PaymentMethodViewModel] { get }
    var applePayViewModel: ApplePayViewModelProtocol { get }
    var oAuthViewModel: OAuthViewModelProtocol { get }
    var cardFormViewModel: CardFormViewModelProtocol { get }
    var theme: PrimerTheme { get }
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) -> Void
}

class DirectCheckoutViewModel: DirectCheckoutViewModelProtocol {
    var theme: PrimerTheme { return settings.theme }
    
    private var amount: Int { return settings.amount }
    private var currency: Currency { return settings.currency }
    
    var amountViewModel: AmountViewModel {
        return AmountViewModel(amount: amount, currency: currency)
    }
    var applePayViewModel: ApplePayViewModelProtocol
    var oAuthViewModel: OAuthViewModelProtocol
    var cardFormViewModel: CardFormViewModelProtocol
    var paymentMethods: [PaymentMethodViewModel] { return paymentMethodConfigService.viewModels }
    
    let clientTokenService: ClientTokenServiceProtocol
    let paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    let settings: PrimerSettings
    
    init(
        with settings: PrimerSettings,
        and applePayViewModel: ApplePayViewModelProtocol,
        and oAuthViewModel: OAuthViewModelProtocol,
        and cardFormViewModel: CardFormViewModelProtocol,
        and clientTokenService: ClientTokenServiceProtocol,
        and paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    ) {
        self.settings = settings
        self.applePayViewModel = applePayViewModel
        self.oAuthViewModel = oAuthViewModel
        self.cardFormViewModel = cardFormViewModel
        self.clientTokenService = clientTokenService
        self.paymentMethodConfigService = paymentMethodConfigService
    }
    
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        self.clientTokenService.loadCheckoutConfig(with: completion)
    }
}

enum PaymentMethodIcon: String {
    case creditCard = "creditCard"
    case appleIcon = "appleIcon"
    case paypal = "paypal"
}

struct PaymentMethodViewModel {
    func toString() -> String {
        switch type {
        case .PAYMENT_CARD: return "Pay by card"
        case .APPLE_PAY: return "Pay"
        case .PAYPAL: return ""
        default: return ""
        }
    }
    
    func toIconName() -> PaymentMethodIcon {
        switch type {
        case .APPLE_PAY: return .appleIcon
        case .PAYPAL: return .paypal
        default: return .creditCard
        }
    }
    
    let type: ConfigPaymentMethodType
}

struct AmountViewModel {
    let amount: Int
    let currency: Currency
    var formattedAmount: String {
        return String(format: "%.2f", (Double(amount) / 100))
    }
    func toLocal() -> String {
        switch currency {
        case .USD:
            return "$\(formattedAmount)"
        case .GBP:
            return "£\(formattedAmount)"
        case .EUR:
            return "€\(formattedAmount)"
        case .JPY:
            return "¥\(amount)"
        case .SEK:
            return "\(amount) SEK"
        case .NOK:
            return "$\(amount) NOK"
        case .DKK:
            return "$\(amount) DKK"
        default:
            return "\(amount)"
        }
    }
}
