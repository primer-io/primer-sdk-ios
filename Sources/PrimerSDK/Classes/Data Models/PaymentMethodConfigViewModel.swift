//
//  PaymentMethodViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 7/10/21.
//

import Foundation

typealias TokenizationCompletion = ((PaymentMethodToken?, Error?) -> Void)

class PaymentMethodConfigViewModel {
    
    internal private(set) var config: PaymentMethodConfig
    private var webViewController: WebViewController?
    internal var position: Int!
    var tokenizationCompletion: TokenizationCompletion!
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    internal private(set) var paymentMethod: PaymentMethodToken?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(config: PaymentMethodConfig) {
        self.config = config
    }
    
    @objc
    func buttonTapped() {
        switch config.type {
        case .hoolah,
                .payNLIdeal:
            tokenize()
        default:
            break
        }
    }
    
    @objc
    func tokenize() {
        let state: AppStateProtocol = DependencyContainer.resolve()

        guard let decodedClientToken = state.decodedClientToken else { return }

        guard let configId = config.id else { return }

        let request = AsyncPaymentMethodTokenizationRequest(
            paymentInstrument: AsyncPaymentMethodOptions(
                paymentMethodType: config.type, paymentMethodConfigId: configId))
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()

        let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
        client.tokenizePaymentMethod(
            clientToken: decodedClientToken,
            paymentMethodTokenizationRequest: request) { [unowned self] result in
                switch result {
                case .success(let paymentMethod):
                    self.paymentMethod = paymentMethod
                    
                    Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, { [unowned self] err in
                        self.tokenizationCompletion?(nil, err)
                        self.tokenizationCompletion = nil
                    })
                    Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, resumeHandler: self)
                case .failure(let err):
                    Primer.shared.delegate?.checkoutFailed?(with: err)
                }
            }
    }
    
    func presentAsyncPaymentMethod(with url: URL) {
        DispatchQueue.main.async { [unowned self] in
            self.webViewController = WebViewController()
            self.webViewController!.url = url
//            self.webViewController!.webViewCompletion = { (_, err) in }
            self.webViewController!.modalPresentationStyle = .fullScreen
            Primer.shared.primerRootVC?.present(self.webViewController!, animated: true, completion: nil)
        }
    }
    
    func startPolling(on url: URL) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
        client.poll(clientToken: state.decodedClientToken, url: url.absoluteString) { result in
            switch result {
            case .success(let res):
                if res.status == .pending {
                    self.startPolling(on: url)
                } else if res.status == .complete {
                    Primer.shared.delegate?.onResumeSuccess?(res.id, resumeHandler: self)
                    self.webViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                } else {
                    // Do what here?
                    fatalError()
                }
            case .failure(let err):
                let nsErr = err as NSError
                if nsErr.domain == NSURLErrorDomain && nsErr.code == -1001 {
                    // Retry
                    self.startPolling(on: url)
                } else {
                    Primer.shared.delegate?.checkoutFailed?(with: err)
                    self.tokenizationCompletion?(nil, err)
                    self.tokenizationCompletion = nil
                }
            }
        }
    }
    
    lazy var title: String = {
        switch config.type {
        case .applePay:
            return "Apple Pay"
        case .payPal:
            return "PayPal"
        case .paymentCard:
            return "Payment Card"
        case .googlePay:
            return "Google Pay"
        case .goCardlessMandate:
            return "Go Cardless"
        case .klarna:
            return "Klarna"
        case .payNLIdeal:
            return "Pay NL Ideal"
        case .apaya:
            return "Apaya"
        case .hoolah:
            return "Hoolah"
        case .unknown:
            return "Unknown"
        }
    }()

    lazy var buttonTitle: String? = {
        switch config.type {
        case .paymentCard:
            return Primer.shared.flow.internalSessionFlow.vaulted
                ? NSLocalizedString("payment-method-type-card-vaulted",
                                    tableName: nil,
                                    bundle: Bundle.primerResources,
                                    value: "Add new card",
                                    comment: "Add new card - Payment Method Type (Card Vaulted)")

                : NSLocalizedString("payment-method-type-card-not-vaulted",
                                    tableName: nil,
                                    bundle: Bundle.primerResources,
                                    value: "Pay with card",
                                    comment: "Pay with card - Payment Method Type (Card Not vaulted)")
        
        case .goCardlessMandate:
            return NSLocalizedString("payment-method-type-go-cardless",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Bank account",
                                     comment: "Bank account - Payment Method Type (Go Cardless)")
        
        case .payNLIdeal:
            return nil
            
        case .apaya:
            return NSLocalizedString("payment-method-type-pay-by-mobile",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Pay by mobile",
                                     comment: "Pay by mobile - Payment By Mobile (Apaya)")
        case .hoolah:
            return nil
        
        case .applePay:
            return nil
        case .googlePay:
            return nil
        case .klarna:
            return nil
        case .payPal:
            return nil
        case .unknown:
            return nil
        }
    }()
    
    lazy var buttonImage: UIImage? = {
        switch config.type {
        case .applePay:
            return UIImage(named: "apple-pay-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .payPal:
            return UIImage(named: "paypal3", in: Bundle.primerResources, compatibleWith: nil)
        case .paymentCard:
            return UIImage(named: "creditCard", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .googlePay:
            return nil
        case .goCardlessMandate:
            return UIImage(named: "rightArrow", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .klarna:
            return UIImage(named: "klarna-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .payNLIdeal:
            return UIImage(named: "iDeal-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .apaya:
            return UIImage(named: "mobile", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .hoolah:
            return UIImage(named: "hoolah-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .unknown:
            return nil
        }
    }()
    
    lazy var buttonColor: UIColor? = {
        switch config.type {
        case .applePay:
            return .black
        case .payPal:
            return UIColor(red: 0.745, green: 0.894, blue: 0.996, alpha: 1)
        case .paymentCard:
            return .white
        case .googlePay:
            return nil
        case .goCardlessMandate:
            return .white
        case .klarna:
            return UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1.0)
        case .payNLIdeal:
            return UIColor(red: 204.0/255, green: 0.0, blue: 102.0/255, alpha: 1.0)
        case .apaya:
            return .white
        case .hoolah:
            return UIColor(red: 214.0/255, green: 55.0/255, blue: 39.0/255, alpha: 1.0)
        case .unknown:
            return nil
        }
    }()
    
    lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .paymentCard,
                .goCardlessMandate,
                .apaya,
                .unknown:
            return theme.colorTheme.text1
        case .applePay,
                .googlePay,
                .hoolah,
                .payNLIdeal,
                .payPal,
                .klarna:
            return nil
        }
    }()
    
    lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .paymentCard,
                .goCardlessMandate,
                .apaya,
                .unknown:
            return 1.0
        case .applePay,
                .googlePay,
                .hoolah,
                .payNLIdeal,
                .payPal,
                .klarna:
            return 0.0
        }
    }()
    
    lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .paymentCard,
                .goCardlessMandate,
                .apaya,
                .unknown:
            return theme.colorTheme.text1
        case .applePay,
                .googlePay,
                .hoolah,
                .payNLIdeal,
                .payPal,
                .klarna:
            return nil
        }
    }()
    
    lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .applePay,
                .hoolah,
                .payNLIdeal:
            return .white
        case .klarna:
            return .black
        case .paymentCard,
                .goCardlessMandate,
                .apaya:
            return theme.colorTheme.text1
        case .payPal,
                .googlePay,
                .unknown:
            return nil
        }
    }()
    
    lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    lazy var buttonCornerRadius: CGFloat? = {
        return 4.0
    }()
    
    lazy var paymentMethodButton: UIButton = {
        let paymentMethodButton = PrimerButton()
        paymentMethodButton.clipsToBounds = true
        paymentMethodButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        paymentMethodButton.imageEdgeInsets = UIEdgeInsets(top: -2, left: 0, bottom: 0, right: 10)
        paymentMethodButton.titleLabel?.font = buttonFont
        if let buttonCornerRadius = buttonCornerRadius {
            paymentMethodButton.layer.cornerRadius = buttonCornerRadius
        }
        paymentMethodButton.backgroundColor = buttonColor
        paymentMethodButton.setTitle(buttonTitle, for: .normal)
        paymentMethodButton.setImage(buttonImage, for: .normal)
        paymentMethodButton.setTitleColor(buttonTitleColor, for: .normal)
        paymentMethodButton.tintColor = buttonTintColor
        paymentMethodButton.layer.borderWidth = buttonBorderWidth
        paymentMethodButton.layer.borderColor = buttonBorderColor?.cgColor
        paymentMethodButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return paymentMethodButton
    }()
}

extension PaymentMethodConfigViewModel: ResumeHandlerProtocol {
    
    func handle(error: Error) {
        self.tokenizationCompletion?(nil, error)
        self.tokenizationCompletion = nil
    }
    
    func handle(newClientToken clientToken: String) {
        do {
            try ClientTokenService.storeClientToken(clientToken)
            let state: AppStateProtocol = DependencyContainer.resolve()
            if let decodedClientToken = state.decodedClientToken {
                if let intent = decodedClientToken.intent {
                    if let redirectUrlStr = decodedClientToken.redirectUrl,
                       let redirectUrl = URL(string: redirectUrlStr) {
                        presentAsyncPaymentMethod(with: redirectUrl)
                    }
                    
                    if let statusUrlStr = decodedClientToken.statusUrl,
                    let statusURL = URL(string: statusUrlStr) {
                        startPolling(on: statusURL)
                    }
                }
                
            } else {
                
            }
        } catch {
            print(error)
        }
    }
    
    func handleSuccess() {
        self.tokenizationCompletion?(self.paymentMethod, nil)
        self.tokenizationCompletion = nil
    }
    
}

enum PollingStatus: String, Codable {
    case pending = "PENDING"
    case complete = "COMPLETE"
}

struct PollingResponse: Decodable {
    let status: PollingStatus
    let id: String
    let source: String
    let urls: PollingURLs
}

struct PollingURLs: Decodable {
    let status: String
    let redirect: String
    let complete: String
}

extension PaymentMethodConfigViewModel {
    
    static var dsa: Int = {
       return 2
    }()
    
}









