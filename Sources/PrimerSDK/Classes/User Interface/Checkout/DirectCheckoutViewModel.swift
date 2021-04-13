#if canImport(UIKit)

protocol DirectCheckoutViewModelProtocol {
    var amountViewModel: AmountViewModel? { get }
    var paymentMethods: [PaymentMethodViewModel] { get }
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void)
}

class DirectCheckoutViewModel: DirectCheckoutViewModelProtocol {
    
    private var amount: Int? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.amount
    }
    
    private var currency: Currency? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.currency
    }

    var amountViewModel: AmountViewModel? {
        guard let amount = amount, let currency = currency else {
            return nil
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        var model = AmountViewModel(amount: amount, currency: currency)
        
        model.disabled = settings.directDebitHasNoAmount
        
        return model
    }
    var paymentMethods: [PaymentMethodViewModel] {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.viewModels
    }
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if state.decodedClientToken.exists {
            let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            paymentMethodConfigService.fetchConfig(completion)
        } else {
            let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
            clientTokenService.loadCheckoutConfig({ [weak self] _ in
                let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                paymentMethodConfigService.fetchConfig(completion)
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
        case .paymentCard:
            return Primer.shared.flow.vaulted
                ? NSLocalizedString("payment-method-type-card-vaulted",
                                    tableName: nil,
                                    bundle: Bundle.primerFramework,
                                    value: "Add a new card",
                                    comment: "Add a new card - Payment Method Type (Card Vaulted)")

                : NSLocalizedString("payment-method-type-card-not-vaulted",
                                    tableName: nil,
                                    bundle: Bundle.primerFramework,
                                    value: "Pay with card",
                                    comment: "Pay with card - Payment Method Type (Card Not vaulted)")

        case .applePay:
            return NSLocalizedString("payment-method-type-apple-pay",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Pay",
                                     comment: "Pay - Payment Method Type (Apple pay)")

        case .goCardlessMandate:
            return NSLocalizedString("payment-method-type-go-cardless",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Bank account",
                                     comment: "Bank account - Payment Method Type (Go Cardless)")

        case .payPal:
            return ""
        case .klarna:
            return ""
        default:
            return ""
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
