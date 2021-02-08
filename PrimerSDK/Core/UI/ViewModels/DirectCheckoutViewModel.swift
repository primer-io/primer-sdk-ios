protocol DirectCheckoutViewModelProtocol {
    var amountViewModel: AmountViewModel { get }
    var paymentMethods: [PaymentMethodViewModel] { get }
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) -> Void
}

class DirectCheckoutViewModel: DirectCheckoutViewModelProtocol {
    private var amount: Int { return state.settings.amount }
    private var currency: Currency { return state.settings.currency }
    
    var amountViewModel: AmountViewModel {
        var vm = AmountViewModel(amount: amount, currency: currency)
        vm.disabled = state.settings.directDebitHasNoAmount
        return vm
    }
    var paymentMethods: [PaymentMethodViewModel] { return state.viewModels }
    
    @Dependency private(set) var clientTokenService: ClientTokenServiceProtocol
    @Dependency private(set) var paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    @Dependency private(set) var state: AppStateProtocol
    
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
        print("🦋 payment option:", self.type)
        switch type {
        case .PAYMENT_CARD: return Primer.flow.vaulted ? "Add a new card".localized() : "Pay with card".localized()
        case .APPLE_PAY: return "Pay"
        case .PAYPAL: return ""
        case .GOCARDLESS_MANDATE: return "Bank account"
        default: return ""
        }
    }
    
    func toIconName() -> ImageName {
        print("🦋 payment option:", self.type)
        switch type {
        case .APPLE_PAY: return ImageName.appleIcon
        case .PAYPAL: return  ImageName.paypal3
        case .GOCARDLESS_MANDATE: return ImageName.rightArrow
        default: return  ImageName.creditCard
        }
    }
    
    let type: ConfigPaymentMethodType
}

struct AmountViewModel {
    let amount: Int
    let currency: Currency
    
    var disabled = false
    
    var formattedAmount: String {
        return String(format: "%.2f", (Double(amount) / 100))
    }
    func toLocal() -> String {
        if (disabled) { return "" }
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
