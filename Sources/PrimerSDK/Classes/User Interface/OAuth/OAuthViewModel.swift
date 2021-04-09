#if canImport(UIKit)

protocol OAuthViewModelProtocol {
    var urlSchemeIdentifier: String? { get }
    func generateOAuthURL(_ host: OAuthHost, with completion: @escaping (Result<String, Error>) -> Void)
    func tokenize(_ host: OAuthHost, with completion: @escaping (Error?) -> Void)
}

class OAuthViewModel: OAuthViewModelProtocol {

    var urlSchemeIdentifier: String? {
        return state.settings.urlSchemeIdentifier
    }

    private var clientToken: DecodedClientToken? { return state.decodedClientToken }
    private var orderId: String? { return state.orderId }
    private var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse? {
        return state.confirmedBillingAgreement
    }
    private var onTokenizeSuccess: PaymentMethodTokenCallBack { return state.settings.onTokenizeSuccess }

    @Dependency private(set) var paypalService: PayPalServiceProtocol
    @Dependency private(set) var tokenizationService: TokenizationServiceProtocol
    @Dependency private(set) var clientTokenService: ClientTokenServiceProtocol
    @Dependency private(set) var paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    @Dependency private(set) var klarnaService: KlarnaServiceProtocol
    @Dependency private(set) var state: AppStateProtocol

    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
    }

    private func loadConfig(_ host: OAuthHost, _ completion: @escaping (Result<String, Error>) -> Void) {
        clientTokenService.loadCheckoutConfig({ [weak self] error in
            if error != nil {
                ErrorHandler.shared.handle(error: error!)
                completion(.failure(PrimerError.payPalSessionFailed))
                return
            }
            self?.paymentMethodConfigService.fetchConfig({ [weak self] error in
                if error != nil {
                    ErrorHandler.shared.handle(error: error!)
                    completion(.failure(PrimerError.payPalSessionFailed))
                    return
                }
                self?.generateOAuthURL(host, with: completion)
            })
        })
    }

    func generateOAuthURL(_ host: OAuthHost, with completion: @escaping (Result<String, Error>) -> Void) {
        if clientToken != nil && state.paymentMethodConfig != nil {

            if host == .klarna {
                return klarnaService.createPaymentSession(completion)
                //                return completion(.success("https://pay.playground.klarna.com/eu/9IUNvHa"))
            }

            switch Primer.flow.uxMode {
            case .CHECKOUT: paypalService.startOrderSession(completion)
            case .VAULT: paypalService.startBillingAgreementSession(completion)
            }
        } else {
            loadConfig(host, completion)
            return
        }
    }

    private func generateBillingAgreementConfirmation(_ host: OAuthHost, with completion: @escaping (Error?) -> Void) {
        paypalService.confirmBillingAgreement({ [weak self] result in
            switch result {
            case .failure(let error):
                log(logLevel: .error, title: "ERROR!", message: error.localizedDescription, prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
            case .success:
                self?.tokenize(host, with: completion)
            }
        })
    }

    private func generatePaypalPaymentInstrument(_ host: OAuthHost, with completion: @escaping (Error?) -> Void) -> PaymentInstrument? {
        switch Primer.flow.uxMode {
        case .CHECKOUT:
            guard let id = orderId else { return nil }
            return PaymentInstrument(paypalOrderId: id)
        case .VAULT:
            guard let agreement = confirmedBillingAgreement else {
                generateBillingAgreementConfirmation(host, with: completion)
                return nil
            }
            return PaymentInstrument(
                paypalBillingAgreementId: agreement.billingAgreementId,
                shippingAddress: agreement.shippingAddress,
                externalPayerInfo: agreement.externalPayerInfo
            )
        }
    }

    func handleTokenization(request: PaymentMethodTokenizationRequest, with completion: @escaping (Error?) -> Void) {
        tokenizationService.tokenize(request: request) { [weak self] result in
            switch result {
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(error)
            case .success(let token):
                log(logLevel: .verbose, title: nil, message: "Token: \(token)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

                switch Primer.flow.uxMode {
                case .VAULT:
                    log(logLevel: .verbose, title: nil, message: "Vaulting", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
                    completion(nil) // self?.onTokenizeSuccess(token, completion)
                case .CHECKOUT:
                    log(logLevel: .verbose, title: nil, message: "Paying", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
                    self?.onTokenizeSuccess(token, completion)
                }
            }
        }
    }

    func tokenize(_ host: OAuthHost, with completion: @escaping (Error?) -> Void) {

        if (host == .klarna) {
            var instrument = PaymentInstrument()

            log(logLevel: .verbose, title: nil, message: "Host: \(host)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

            klarnaService.finalizePaymentSession { [weak self] result in
                switch result {
                case .failure(let err):
                    completion(err)
                case .success(let res):
                    instrument.sessionData = res.sessionData

                    if Primer.flow.vaulted {
                        // create customer token
                        self?.klarnaService.createKlarnaCustomerToken { (result) in
                            switch result {
                            case .failure(let err):
                                ErrorHandler.shared.handle(error: err)
                                completion(err)
                            case .success(let response):
                                instrument.klarnaCustomerToken = response.customerTokenId
                                instrument.sessionData = response.sessionData

                                log(logLevel: .verbose, title: nil, message: "Instrument: \(instrument)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

                                guard let state = self?.state else { return }

                                let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)

                                log(logLevel: .verbose, title: nil, message: "Request: \(request)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

                                self?.handleTokenization(request: request, with: completion)
                            }
                        }

                    } else {
                        instrument.klarnaAuthorizationToken = self?.state.authorizationToken

                        log(logLevel: .verbose, title: nil, message: "Instrument: \(instrument)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

                        guard let state = self?.state else { return }

                        let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)

                        log(logLevel: .verbose, title: nil, message: "Request: \(request)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

                        self?.handleTokenization(request: request, with: completion)
                    }

                }
            }

        } else {
            guard let instrument = generatePaypalPaymentInstrument(host, with: completion) else { return }

            let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)

            log(logLevel: .verbose, title: nil, message: "Request: \(request)", prefix: "🔥", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

            handleTokenization(request: request, with: completion)
        }
    }
}

#endif
