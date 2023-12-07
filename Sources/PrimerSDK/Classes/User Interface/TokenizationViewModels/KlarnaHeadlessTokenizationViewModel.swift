#if canImport(PrimerKlarnaSDK)
import Foundation
import PrimerKlarnaSDK

class KlarnaHeadlessTokenizationViewModel: PaymentMethodTokenizationViewModel {
    // MARK: - PaymentStage
    enum PaymentStage {
        case createSession
        case authorizeSession
        case finalizeSession
    }
    
    // MARK: - Properties
    private var currentPaymentStage: PaymentStage = .createSession
    private var klarnaPaymentSession: Response.Body.Klarna.CreatePaymentSession?
    private var klarnaCustomerTokenAPIResponse: Response.Body.Klarna.CustomerToken?
    private var klarnaPaymentSessionAttachment: Request.Body.Klarna.CreatePaymentSession.Attachment?
    private var authorizationToken: String?
    
    // MARK: - Closures
    var klarnaPaymentSessionCreated: ((_ klarnaPaymentSession: Response.Body.Klarna.CreatePaymentSession?) -> Void)?
    var klarnaPaymentSessionCompleted: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    var klarnaPaymentSessionFinalized: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    
    // MARK: - Set
    func setAttachment(attachment: Request.Body.Klarna.CreatePaymentSession.Attachment?) {
        self.klarnaPaymentSessionAttachment = attachment
    }
    
    // MARK: - Validate
    override func validate() throws {
        guard 
            let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
            decodedJWTToken.isValid
        else {
            let error = PrimerError.invalidClientToken(
                userInfo: [
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ],
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: error)
            throw error
        }
        
        guard decodedJWTToken.pciUrl != nil else {
            let error = PrimerError.invalidClientToken(
                userInfo: [
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ],
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: error)
            throw error
        }
        
        guard config.id != nil else {
            let error = PrimerError.invalidValue(
                key: "configuration.id",
                value: config.id,
                userInfo: [
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ],
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: error)
            throw error
        }
        
        let klarnaSessionType: KlarnaSessionType = getSessionType()
        
        if PrimerInternal.shared.intent == .checkout && AppState.current.amount == nil {
            let error = PrimerError.invalidSetting(
                name: "amount",
                value: nil,
                userInfo: [
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ],
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: error)
            throw error
        }
        
        if case .hostedPaymentPage = klarnaSessionType {
            if AppState.current.amount == nil {
                let error = PrimerError.invalidSetting(
                    name: "amount",
                    value: nil,
                    userInfo: [
                        "file": #file, 
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ], 
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: error)
                throw error
            }

            if AppState.current.currency == nil {
                let error = PrimerError.invalidSetting(
                    name: "currency",
                    value: nil,
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: error)
                throw error
            }
            
            let clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
            let lineItems = clientSession?.order?.lineItems ?? []
            
            if lineItems.isEmpty {
                let error = PrimerError.invalidValue(
                    key: "lineItems",
                    value: nil,
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: error)
                throw error
            }
            
            if !(lineItems.filter({ $0.amount == nil })).isEmpty {
                let error = PrimerError.invalidValue(
                    key: "settings.orderItems",
                    value: nil,
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: error)
                throw error
            }
        }
    }
    
    // MARK: - Pre-tokenization
    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.config.type,
                    url: nil
                ),
                extra: nil,
                objectType: .button,
                objectId: .select,
                objectClass: "\(Self.self)",
                place: .paymentMethodPopup
            )
        )
        Analytics.Service.record(event: event)

        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then { () -> Promise<Response.Body.Klarna.CreatePaymentSession> in
                return self.createPaymentSession()
            }
            .then { (session) -> Promise<Void> in
                self.klarnaPaymentSession = session
                self.currentPaymentStage = .createSession
                return self.awaitUserInput()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .then { () -> Promise<Void> in
                if self.currentPaymentStage == .finalizeSession {
                    return self.awaitUserInput()
                } else {
                    return Promise { seal in
                        seal.fulfill()
                    }
                }
            }
            .then { () -> Promise<Response.Body.Klarna.CustomerToken> in
                return self.authorizePaymentSession(authorizationToken: self.authorizationToken!)
            }
            .done { (klarnaCustomerTokenAPIResponse) in
                self.klarnaCustomerTokenAPIResponse = klarnaCustomerTokenAPIResponse
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }
    
    // MARK: - Await user input
    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            switch currentPaymentStage {
            case .createSession:
                self.klarnaPaymentSessionCreated?(self.klarnaPaymentSession)
                self.currentPaymentStage = .authorizeSession
                seal.fulfill()
                
            case .authorizeSession:
                self.klarnaPaymentSessionCompleted = { (authorizationToken, error) in
                    if let error = error {
                        seal.reject(error)
                    } else if let authorizationToken = authorizationToken {
                        self.authorizationToken = authorizationToken
                        seal.fulfill()
                    } else {
                        self.currentPaymentStage = .finalizeSession
                        seal.fulfill()
                    }
                }
                
            case .finalizeSession:
                self.klarnaPaymentSessionFinalized = { (authorizationToken, error) in
                    if let error = error {
                        seal.reject(error)
                    } else if let authorizationToken = authorizationToken {
                        self.authorizationToken = authorizationToken
                        seal.fulfill()
                    } else {
                        precondition(false, "Should never end up in here")
                    }
                }
            }
        }
    }
    
    // MARK: - Tokenization
    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.checkouEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.checkouEventsNotifierModule.fireDidFinishTokenizationEvent()
            }
            .done {
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }

    // MARK: - Post-tokenization
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    // MARK: - Tokenize
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let klarnaCustomerToken = self.klarnaCustomerTokenAPIResponse?.customerTokenId else {
                let error = PrimerError.invalidValue(key: "tokenization.klarnaCustomerToken", value: nil, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: error)
                seal.reject(error)
                return
            }

            guard let sessionData = self.klarnaCustomerTokenAPIResponse?.sessionData else {
                let error = PrimerError.invalidValue(key: "tokenization.sessionData", value: nil, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: error)
                seal.reject(error)
                return
            }

            let paymentInstrument = KlarnaCustomerTokenPaymentInstrument(
                klarnaCustomerToken: klarnaCustomerToken,
                sessionData: sessionData)

            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)

            let tokenizationService: TokenizationServiceProtocol = TokenizationService()

            firstly {
                tokenizationService.tokenize(requestBody: requestBody)
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }
}

// MARK: - Helpers
private extension KlarnaHeadlessTokenizationViewModel {
    func getSessionType() -> KlarnaSessionType {
        if PrimerInternal.shared.intent == .vault {
            return .recurringPayment
        } else {
            return .hostedPaymentPage
        }
    }
}

// MARK: - Create payment session
private extension KlarnaHeadlessTokenizationViewModel {
    func createPaymentSession() -> Promise<Response.Body.Klarna.CreatePaymentSession> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let error = PrimerError.invalidClientToken(
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: error)
                seal.reject(error)
                return
            }

            guard let configId = config.id else {
                let error = PrimerError.missingPrimerConfiguration(
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: error)
                seal.reject(error)
                return
            }

            let klarnaSessionType: KlarnaSessionType = PrimerInternal.shared.intent == .vault ? .recurringPayment : .hostedPaymentPage

            var amount = AppState.current.amount
            if amount == nil && PrimerInternal.shared.intent == .checkout {
                let error = PrimerError.invalidSetting(
                    name: "amount",
                    value: nil,
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: error)
                seal.reject(error)
                return
            }

            if case .hostedPaymentPage = klarnaSessionType {
                if amount == nil {
                    let error = PrimerError.invalidSetting(
                        name: "amount",
                        value: nil,
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString
                    )
                    ErrorHandler.handle(error: error)
                    seal.reject(error)
                    return
                }

                if AppState.current.currency == nil {
                    let error = PrimerError.invalidSetting(
                        name: "currency",
                        value: nil,
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString
                    )
                    ErrorHandler.handle(error: error)
                    seal.reject(error)
                    return
                }

                let clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
                let lineItems = clientSession?.order?.lineItems ?? []
                
                if lineItems.isEmpty {
                    let error = PrimerError.invalidValue(
                        key: "settings.orderItems",
                        value: nil,
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString
                    )
                    ErrorHandler.handle(error: error)
                    seal.reject(error)
                    return
                }

                if !(lineItems.filter({ $0.amount == nil })).isEmpty {
                    let error = PrimerError.invalidValue(
                        key: "settings.orderItems.amount",
                        value: nil,
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString
                    )
                    ErrorHandler.handle(error: error)
                    seal.reject(error)
                    return
                }
                
                self.logger.info(message: "Klarna amount: \(amount!) \(AppState.current.currency!.rawValue)")

            } else if case .recurringPayment = klarnaSessionType {
                amount = nil
            }

            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            let body = Request.Body.Klarna.CreatePaymentSession(
                paymentMethodConfigId: configId,
                sessionType: .recurringPayment,
                localeData: PrimerSettings.current.localeData,
                description: PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
                redirectUrl: settings.paymentMethodOptions.urlScheme,
                totalAmount: nil,
                orderItems: nil,
                attachment: self.klarnaPaymentSessionAttachment
            )
            
            let apiClient: PrimerAPIClientProtocol = PaymentMethodTokenizationViewModel.apiClient ?? PrimerAPIClient()

            apiClient.createKlarnaPaymentSession(clientToken: decodedJWTToken, klarnaCreatePaymentSessionAPIRequest: body) { (result) in
                switch result {
                case .failure(let error):
                    seal.reject(error)

                case .success(let res):
                    self.logger.info(message: "\(res)")
                    seal.fulfill(res)
                }
            }
        }
    }
}

// MARK: - Authorize payment session
private extension KlarnaHeadlessTokenizationViewModel {
    func authorizePaymentSession(authorizationToken: String) -> Promise<Response.Body.Klarna.CustomerToken> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let error = PrimerError.invalidClientToken(
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: error)
                seal.reject(error)
                return
            }

            guard 
                let configId = PrimerAPIConfigurationModule.apiConfiguration?.getConfigId(
                    for: PrimerPaymentMethodType.klarna.rawValue
                ),
                let sessionId = self.klarnaPaymentSession?.sessionId
            else {
                let error = PrimerError.missingPrimerConfiguration(
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: error)
                seal.reject(error)
                return
            }

            let body = Request.Body.Klarna.CreateCustomerToken(
                paymentMethodConfigId: configId,
                sessionId: sessionId,
                authorizationToken: authorizationToken,
                description: PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
                localeData: PrimerSettings.current.localeData
            )

            let apiClient: PrimerAPIClientProtocol = PaymentMethodTokenizationViewModel.apiClient ?? PrimerAPIClient()

            apiClient.createKlarnaCustomerToken(clientToken: decodedJWTToken, klarnaCreateCustomerTokenAPIRequest: body) { (result) in
                switch result {
                case .failure(let error):
                    seal.reject(error)
                case .success(let response):
                    seal.fulfill(response)
                }
            }
        }
    }
}

// MARK: - Finalize payment session
private extension KlarnaHeadlessTokenizationViewModel {
    func finalizePaymentSession() -> Promise<Response.Body.Klarna.CustomerToken> {
        return Promise { seal in
            self.finalizePaymentSession { result in
                switch result {
                case .failure(let error):
                    seal.reject(error)
                case .success(let res):
                    seal.fulfill(res)
                }
            }
        }
    }

    func finalizePaymentSession(completion: @escaping (Result<Response.Body.Klarna.CustomerToken, Error>) -> Void) {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let error = PrimerError.invalidClientToken(
                userInfo: [
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ],
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: error)
            completion(.failure(error))
            return
        }

        guard 
            let configId = PrimerAPIConfigurationModule.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.klarna.rawValue),
            let sessionId = self.klarnaPaymentSession?.sessionId
        else {
            let error = PrimerError.missingPrimerConfiguration(
                userInfo: [
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ],
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: error)
            completion(.failure(error))
            return
        }

        let body = Request.Body.Klarna.FinalizePaymentSession(paymentMethodConfigId: configId, sessionId: sessionId)
        self.logger.info(message: "config ID: \(configId)")

        let apiClient: PrimerAPIClientProtocol = PaymentMethodTokenizationViewModel.apiClient ?? PrimerAPIClient()

        apiClient.finalizeKlarnaPaymentSession(clientToken: decodedJWTToken, klarnaFinalizePaymentSessionRequest: body) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                self.logger.info(message: "\(response)")
                completion(.success(response))
            }
        }
    }
}
#endif
