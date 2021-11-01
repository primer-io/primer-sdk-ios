#if canImport(UIKit)

import UIKit
import AuthenticationServices
import SafariServices

class PayPalTokenizationViewModel: PaymentMethodTokenizationViewModel, ExternalPaymentMethodTokenizationViewModelProtocol {
    
    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?
    private var session: Any!
    private var paypalOrderId: String?
    private var billingAgreementToken: String?
    private var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse?
    
    override lazy var title: String = {
        return "PayPal"
    }()
    
    override lazy var buttonTitle: String? = {
        switch config.type {
        case .payPal:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonImage: UIImage? = {
        switch config.type {
        case .payPal:
            return UIImage(named: "paypal3", in: Bundle.primerResources, compatibleWith: nil)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonColor: UIColor? = {
        switch config.type {
        case .payPal:
            return UIColor(red: 0.745, green: 0.894, blue: 0.996, alpha: 1)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .payPal:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .payPal:
            return 0.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    override lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .payPal:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .payPal:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    override lazy var buttonCornerRadius: CGFloat? = {
        return 4.0
    }()
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PaymentException.missingClientToken
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.tokenizationPreRequestFailed
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PaymentException.missingConfigurationId
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.coreUrl != nil else {
            let err = PrimerError.invalidValue(key: "coreUrl")
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
    }
    
    @objc
    override func startTokenizationFlow() {
        super.startTokenizationFlow()
        
        do {
            try validate()
        } catch {
            DispatchQueue.main.async {
                Primer.shared.delegate?.checkoutFailed?(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        firstly {
            self.tokenize()
        }
        .done { paymentMethod in
            self.paymentMethod = paymentMethod
            
            if Primer.shared.flow.internalSessionFlow.vaulted {
                Primer.shared.delegate?.tokenAddedToVault?(paymentMethod)
            }

            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, resumeHandler: self)
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, { [unowned self] err in
                if let err = err {
                    self.handleFailedTokenizationFlow(error: err)
                } else {
                    self.handleSuccessfulTokenizationFlow()
                }
            })
        }
        .catch { err in
            Primer.shared.delegate?.checkoutFailed?(with: err)
            self.handleFailedTokenizationFlow(error: err)
        }
    }
    
    func tokenize() -> Promise <PaymentMethodToken> {
        return Promise { seal in
            firstly {
                self.fetchOAuthURL()
            }
            .then { url -> Promise<URL> in
                self.willPresentExternalView?()
                return self.createOAuthSession(url)
            }
            .then { url -> Promise<PaymentInstrument> in
                return self.generatePaypalPaymentInstrument()
            }
            .then { instrument -> Promise<PaymentMethodToken> in
                return self.tokenize(instrument: instrument)
            }
            .done { token in
                seal.fulfill(token)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func fetchOAuthURL() -> Promise<URL> {
        return Promise { seal in
            switch Primer.shared.flow.internalSessionFlow.uxMode {
            case .CHECKOUT:
                self.startOrderSession { result in
                    switch result {
                    case .success(let urlStr):
                        guard let url = URL(string: urlStr) else {
                            seal.reject(PrimerError.failedToLoadSession)
                            return
                        }
                        
                        seal.fulfill(url)
                        
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            case .VAULT:
                self.startBillingAgreementSession { result in
                    switch result {
                    case .success(let urlStr):
                        guard let url = URL(string: urlStr) else {
                            seal.reject(PrimerError.failedToLoadSession)
                            return
                        }
                        
                        seal.fulfill(url)
                        
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            }
        }
    }
    
    private func createOAuthSession(_ url: URL) -> Promise<URL> {
        return Promise { seal in
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            guard let urlScheme = settings.urlScheme else {
                seal.reject(PrimerError.missingURLScheme)
                return
            }
            
            if #available(iOS 13, *) {
                session =  ASWebAuthenticationSession(
                    url: url,
                    callbackURLScheme: urlScheme,
                    completionHandler: { (url, error) in
                        if let error = error {
                            seal.reject(error)
                            
                        } else if let url = url {
                            seal.fulfill(url)
                        }
                    }
                )
                
                (session as! ASWebAuthenticationSession).presentationContextProvider = self
                (session as! ASWebAuthenticationSession).start()
                
            } else if #available(iOS 11, *) {
                session = SFAuthenticationSession(
                    url: url,
                    callbackURLScheme: urlScheme,
                    completionHandler: { (url, err) in
                        if let err = err {
                            seal.reject(err)
                            
                        } else if let url = url {
                            seal.fulfill(url)
                        }
                    }
                )

                (session as! SFAuthenticationSession).start()
            }
            
            didPresentExternalView?()
        }
    }
    
    private func generatePaypalPaymentInstrument() -> Promise<PaymentInstrument> {
        return Promise { seal in
            generatePaypalPaymentInstrument { result in
                switch result {
                case .success(let paymentInstrument):
                    seal.fulfill(paymentInstrument)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    private func generatePaypalPaymentInstrument(_ completion: @escaping (Result<PaymentInstrument, Error>) -> Void) {
        switch Primer.shared.flow.internalSessionFlow.uxMode {
        case .CHECKOUT:
            let state: AppStateProtocol = DependencyContainer.resolve()
            guard let paypalOrderId = self.paypalOrderId else {
                completion(.failure(PrimerError.orderIdMissing))
                return
            }
            
            let paymentInstrument = PaymentInstrument(paypalOrderId: paypalOrderId)
            completion(.success(paymentInstrument))
            
        case .VAULT:
            guard let confirmedBillingAgreement = self.confirmedBillingAgreement else {
                generateBillingAgreementConfirmation { [weak self] err in
                    if let err = err {
                        completion(.failure(err))
                    } else {
                        self?.generatePaypalPaymentInstrument(completion)
                    }
                }
                return
            }
            let paymentInstrument = PaymentInstrument(
                paypalBillingAgreementId: confirmedBillingAgreement.billingAgreementId,
                shippingAddress: confirmedBillingAgreement.shippingAddress,
                externalPayerInfo: confirmedBillingAgreement.externalPayerInfo
            )
            
            completion(.success(paymentInstrument))
        }
    }
    
    private func generateBillingAgreementConfirmation(_ completion: @escaping (Error?) -> Void) {
        self.confirmBillingAgreement({ result in
            switch result {
            case .failure(let error):
                log(logLevel: .error, title: "ERROR!", message: error.localizedDescription, prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
                completion(PrimerError.payPalSessionFailed)
            case .success:
                completion(nil)
            }
        })
    }
    
    private func tokenize(instrument: PaymentInstrument) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            let state: AppStateProtocol = DependencyContainer.resolve()
            let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)
            
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            tokenizationService.tokenize(request: request) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                    
                case .success(let token):
                    seal.fulfill(token)
                }
            }
        }
    }
    
    private func startOrderSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            return completion(.failure(PrimerError.clientTokenNull))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .payPal) else {
            return completion(.failure(PrimerError.configFetchFailed))
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        guard let amount = settings.amount else {
            return completion(.failure(PrimerError.amountMissing))
        }

        guard let currency = settings.currency else {
            return completion(.failure(PrimerError.currencyMissing))
        }

        guard var urlScheme = settings.urlScheme else {
            return completion(.failure(PrimerError.missingURLScheme))
        }
        
        if urlScheme.suffix(3) == "://" {
            urlScheme = urlScheme.replacingOccurrences(of: "://", with: "")
        }

        let body = PayPalCreateOrderRequest(
            paymentMethodConfigId: configId,
            amount: amount,
            currencyCode: currency,
            returnUrl: "\(urlScheme)://paypal-success",
            cancelUrl: "\(urlScheme)://paypal-cancel"
        )
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.payPalStartOrderSession(clientToken: decodedClientToken, payPalCreateOrderRequest: body) { (result) in
            switch result {
            case .failure:
                completion(.failure(PrimerError.payPalSessionFailed))
            case .success(let response):
                self.paypalOrderId = response.orderId
                completion(.success(response.approvalUrl))
            }
        }
    }
    
    private func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            return completion(.failure(PrimerError.payPalSessionFailed))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .payPal) else {
            return completion(.failure(PrimerError.payPalSessionFailed))
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        guard var urlScheme = settings.urlScheme else {
            return completion(.failure(PrimerError.missingURLScheme))
        }
        
        if urlScheme.suffix(3) == "://" {
            urlScheme = urlScheme.replacingOccurrences(of: "://", with: "")
        }

        let body = PayPalCreateBillingAgreementRequest(
            paymentMethodConfigId: configId,
            returnUrl: "\(urlScheme)://paypal-success",
            cancelUrl: "\(urlScheme)://paypal-cancel"
        )
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.payPalStartBillingAgreementSession(clientToken: decodedClientToken, payPalCreateBillingAgreementRequest: body) { (result) in
            switch result {
            case .failure:
                completion(.failure(PrimerError.payPalSessionFailed))
            case .success(let config):
                self.billingAgreementToken = config.tokenId
                completion(.success(config.approvalUrl))
            }
        }
    }
    
    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            return completion(.failure(PrimerError.payPalSessionFailed))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .payPal) else {
            return completion(.failure(PrimerError.payPalSessionFailed))
        }

        guard let billingAgreementToken = self.billingAgreementToken else {
            return completion(.failure(PrimerError.payPalSessionFailed))
        }

        let body = PayPalConfirmBillingAgreementRequest(paymentMethodConfigId: configId, tokenId: billingAgreementToken)
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.payPalConfirmBillingAgreement(clientToken: decodedClientToken, payPalConfirmBillingAgreementRequest: body) { (result) in
            switch result {
            case .failure:
                completion(.failure(PrimerError.payPalSessionFailed))
            case .success(let response):
                self.confirmedBillingAgreement = response
                completion(.success(response))
            }
        }
    }
}

extension PayPalTokenizationViewModel {
    
    override func handle(error: Error) {
        self.completion?(nil, error)
        self.completion = nil
    }
    
    override func handle(newClientToken clientToken: String) {
        try? ClientTokenService.storeClientToken(clientToken)
    }
    
    override func handleSuccess() {
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
    }
    
}

@available(iOS 11.0, *)
extension PayPalTokenizationViewModel: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 12.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.keyWindow ?? ASPresentationAnchor()
    }
    
}

#endif
