protocol DirectCheckoutViewModelProtocol {
    var amountViewModel: AmountViewModel { get }
    var paymentMethods: [PaymentMethodViewModel] { get }
    var theme: PrimerTheme { get }
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) -> Void
}

class DirectCheckoutViewModel: DirectCheckoutViewModelProtocol {
    var theme: PrimerTheme { return state.settings.theme }
    
    private var amount: Int { return state.settings.amount }
    private var currency: Currency { return state.settings.currency }
    
    var amountViewModel: AmountViewModel { return AmountViewModel(amount: amount, currency: currency) }
    var paymentMethods: [PaymentMethodViewModel] { return state.viewModels }
    
    let clientTokenService: ClientTokenServiceProtocol
    let paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    private var state: AppStateProtocol
    
    init(context: CheckoutContextProtocol) {
        self.state = context.state
        self.clientTokenService = context.serviceLocator.clientTokenService
        self.paymentMethodConfigService = context.serviceLocator.paymentMethodConfigService
    }
    
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        if (state.decodedClientToken.exists) {
            paymentMethodConfigService.fetchConfig(completion)
        } else {
            clientTokenService.loadCheckoutConfig({ [weak self] error in
                self?.paymentMethodConfigService.fetchConfig(completion)
            })
        }
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
        case .PAYMENT_CARD: return "Pay by card".localized()
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
