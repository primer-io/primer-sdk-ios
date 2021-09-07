#if canImport(UIKit)

internal protocol OAuthViewModelProtocol {
    var urlSchemeIdentifier: String? { get }
    func generateOAuthURL(_ host: OAuthHost, with completion: @escaping (Result<String, Error>) -> Void)
    func tokenize(_ host: OAuthHost, with completion: @escaping (Error?) -> Void)
}

internal class OAuthViewModel: OAuthViewModelProtocol {

    var urlSchemeIdentifier: String? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.urlSchemeIdentifier
    }

    private var clientToken: DecodedClientToken? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.decodedClientToken
    }
    private var orderId: String? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.orderId
    }
    private var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.confirmedBillingAgreement
    }
    private var authorizePayment: PaymentMethodTokenCallBack {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.authorizePayment
    }
    private var onTokenizeSuccess: TokenizationSuccessCallBack {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.onTokenizeSuccess
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    private func loadConfig(_ host: OAuthHost, _ completion: @escaping (Result<String, Error>) -> Void) {
        let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
        clientTokenService.loadCheckoutConfig({ err in
            if let err = err {
                _ = ErrorHandler.shared.handle(error: err)
                if err is PrimerError {
                    completion(.failure(err))
                } else {
                    completion(.failure(PrimerError.configFetchFailed))
                }

            } else {
                let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                paymentMethodConfigService.fetchConfig({ [weak self] err in
                    if let err = err {
                        _ = ErrorHandler.shared.handle(error: err)
                        completion(.failure(PrimerError.requestFailed))
                    } else {
                        self?.generateOAuthURL(host, with: completion)
                    }
                })
            }
        })
    }

    func generateOAuthURL(_ host: OAuthHost, with completion: @escaping (Result<String, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()

        if clientToken != nil && state.paymentMethodConfig != nil {
            if host == .klarna {
                let klarnaService: KlarnaServiceProtocol = DependencyContainer.resolve()
                klarnaService.createPaymentSession(completion)

            } else {
                let paypalService: PayPalServiceProtocol = DependencyContainer.resolve()

                switch Primer.shared.flow.internalSessionFlow.uxMode {
                case .CHECKOUT:
                    paypalService.startOrderSession(completion)
                case .VAULT:
                    paypalService.startBillingAgreementSession(completion)
                }
            }

        } else {
            loadConfig(host, completion)
        }
    }

    private func generateBillingAgreementConfirmation(_ host: OAuthHost, with completion: @escaping (Error?) -> Void) {
        let paypalService: PayPalServiceProtocol = DependencyContainer.resolve()
        paypalService.confirmBillingAgreement({ [weak self] result in
            switch result {
            case .failure(let error):
                log(logLevel: .error, title: "ERROR!", message: error.localizedDescription, prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
                completion(PrimerError.payPalSessionFailed)
            case .success:
                self?.tokenize(host, with: completion)
            }
        })
    }

    private func generatePaypalPaymentInstrument(_ host: OAuthHost, with completion: @escaping (Error?) -> Void) -> PaymentMethodDetailsProtocol? {
        switch Primer.shared.flow.internalSessionFlow.uxMode {
        case .CHECKOUT:
            guard let id = orderId else { return nil }
            return PaymentMethod.PayPal.Details(paypalOrderId: id)
        case .VAULT:
            guard let agreement = confirmedBillingAgreement else {
                generateBillingAgreementConfirmation(host, with: completion)
                return nil
            }
            return PaymentMethod.PayPal.Details(paypalBillingAgreementId: agreement.billingAgreementId,
                                               shippingAddress: agreement.shippingAddress,
                                               externalPayerInfo: agreement.externalPayerInfo)
        }
    }

    func handleTokenization(request: PaymentMethodTokenizationRequest, with completion: @escaping (Error?) -> Void) {
        let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
        tokenizationService.tokenize(request: request) { [weak self] result in
            switch result {
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(error)
            case .success(let token):
                log(logLevel: .verbose, title: nil, message: "Token: \(token)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

                switch Primer.shared.flow.internalSessionFlow.uxMode {
                case .VAULT:
                    log(logLevel: .verbose, title: nil, message: "Vaulting", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
                    
                    completion(nil) // self?.onTokenizeSuccess(token, completion)
                case .CHECKOUT:
                    log(logLevel: .verbose, title: nil, message: "Paying", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
                    self?.authorizePayment(token, completion)
                    self?.onTokenizeSuccess(token, completion)
                }
            }
        }
    }

    // FIXME: This function is just the first step of tokenization for Klarna (fetches session data first).
    // The actual tokenization call takes place in handleTokenization above.
    // Merge with handleTokenization, as they're one.
    func tokenize(_ host: OAuthHost, with completion: @escaping (Error?) -> Void) {
        if (host == .klarna) {
            var paymentMethodDetails: PaymentMethodDetailsProtocol!

            log(logLevel: .verbose, title: nil, message: "Host: \(host)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

            let klarnaService: KlarnaServiceProtocol = DependencyContainer.resolve()

            if Primer.shared.flow.internalSessionFlow.vaulted {
                // create customer token
                klarnaService.createKlarnaCustomerToken { [weak self] (result) in
                    switch result {
                    case .failure(let err):
                        _ = ErrorHandler.shared.handle(error: err)
                        completion(err)
                    case .success(let response):
                        paymentMethodDetails = PaymentMethod.Klarna.Details(klarnaAuthorizationToken: nil, klarnaCustomerToken: response.customerTokenId, sessionData: response.sessionData)

                        log(logLevel: .verbose, title: nil, message: "paymentMethodDetails: \(paymentMethodDetails)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

                        let state: AppStateProtocol = DependencyContainer.resolve()

                        let request = PaymentMethodTokenizationRequest(paymentInstrument: paymentMethodDetails, state: state)

                        log(logLevel: .verbose, title: nil, message: "Request: \(request)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

                        self?.handleTokenization(request: request, with: completion)
                    }
                }

            } else {
                klarnaService.finalizePaymentSession { [weak self] result in
                    switch result {
                    case .failure(let err):
                        completion(err)
                    case .success(let res):
                        let state: AppStateProtocol = DependencyContainer.resolve()
                        paymentMethodDetails = PaymentMethod.Klarna.Details(klarnaAuthorizationToken: state.authorizationToken, klarnaCustomerToken: nil, sessionData: res.sessionData)

                        log(logLevel: .verbose, title: nil, message: "paymentMethodDetails: \(paymentMethodDetails)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

                        let request = PaymentMethodTokenizationRequest(paymentInstrument: paymentMethodDetails, state: state)

                        log(logLevel: .verbose, title: nil, message: "Request: \(request)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

                        self?.handleTokenization(request: request, with: completion)
                    }
                }
            }
        
        } else {
            guard let instrument = generatePaypalPaymentInstrument(host, with: completion) else { return }
            let state: AppStateProtocol = DependencyContainer.resolve()

            let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)

            log(logLevel: .verbose, title: nil, message: "Request: \(request)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

            handleTokenization(request: request, with: completion)
        }
    }
}

#endif
