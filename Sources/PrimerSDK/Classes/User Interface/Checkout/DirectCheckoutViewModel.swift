#if canImport(UIKit)

protocol DirectCheckoutViewModelProtocol {
    var amountViewModel: AmountViewModel { get }
    var paymentMethods: [PaymentMethodViewModel] { get }
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void)
}

class DirectCheckoutViewModel: DirectCheckoutViewModelProtocol {
    private var amount: Int {
        guard let amount = state.settings.amount else { fatalError("Direct checkout requires amount value!") }
        return amount
    }
    private var currency: Currency {
        guard let currency = state.settings.currency else { fatalError("Direct checkout requires currency value!") }
        return currency
    }

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
        if state.decodedClientToken.exists {
            paymentMethodConfigService.fetchConfig(completion)
        } else {
            clientTokenService.loadCheckoutConfig({ [weak self] _ in
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
        log(logLevel: .debug, title: nil, message: "Payment option: \(self.type)", prefix: "🦋", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
        switch type {
        case .paymentCard: return Primer.flow.vaulted ? "Add a new card".localized() : "Pay with card".localized()
        case .applePay: return "Pay"
        case .payPal: return ""
        case .goCardlessMandate: return "Bank account"
        case .klarna: return ""
        default: return ""
        }
    }

    func toIconName() -> ImageName {
        log(logLevel: .debug, title: nil, message: "Payment option: \(self.type)", prefix: "🦋", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
        switch type {
        case .applePay: return ImageName.appleIcon
        case .payPal: return  ImageName.paypal3
        case .goCardlessMandate: return ImageName.rightArrow
        case .klarna: return ImageName.klarna
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
        if disabled { return "" }
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

#endif
