// swiftlint:disable cyclomatic_complexity

import Foundation
import UIKit

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
#endif

class KlarnaTokenizationViewModel: PaymentMethodTokenizationViewModel {

    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?

    #if canImport(PrimerKlarnaSDK)
    private var klarnaViewController: PrimerKlarnaViewController?
    #endif

    #if DEBUG
    private var demoThirdPartySDKViewController: PrimerThirdPartySDKViewController?
    #endif
    private var klarnaPaymentSession: Response.Body.Klarna.PaymentSession?
    private var klarnaCustomerTokenAPIResponse: Response.Body.Klarna.CustomerToken?
    private var klarnaPaymentSessionCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    private var authorizationToken: String?

    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard decodedJWTToken.pciUrl != nil else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file,
                                                                                                     "class": "\(Self.self)",
                                                                                                     "function": #function,
                                                                                                     "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        let klarnaSessionType: KlarnaSessionType = PrimerInternal.shared.intent == .vault ? .recurringPayment : .oneOffPayment

        if PrimerInternal.shared.intent == .checkout && AppState.current.amount == nil {
            let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file,
                                                                                        "class": "\(Self.self)",
                                                                                        "function": #function,
                                                                                        "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        if case .oneOffPayment = klarnaSessionType {
            if AppState.current.amount == nil {
                let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file,
                                                                                            "class": "\(Self.self)",
                                                                                            "function": #function,
                                                                                            "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            if AppState.current.currency == nil {
                let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file,
                                                                                              "class": "\(Self.self)",
                                                                                              "function": #function,
                                                                                              "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            if (PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.lineItems ?? []).isEmpty {
                let err = PrimerError.invalidValue(key: "lineItems", value: nil, userInfo: ["file": #file,
                                                                                            "class": "\(Self.self)",
                                                                                            "function": #function,
                                                                                            "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            if !(PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.lineItems ?? []).filter({ $0.amount == nil }).isEmpty {
                let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file,
                                                                                                      "class": "\(Self.self)",
                                                                                                      "function": #function,
                                                                                                      "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        }
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: self.config.type,
                url: nil),
            extra: nil,
            objectType: .button,
            objectId: .select,
            objectClass: "\(Self.self)",
            place: .paymentMethodPopup
        )
        Analytics.Service.record(event: event)

        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: self.uiModule.makeIconImageView(withDimension: 24.0), message: nil)

        return Promise { seal in
            #if canImport(PrimerKlarnaSDK)
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
            .then { () -> Promise<Response.Body.Klarna.PaymentSession> in
                return self.createPaymentSession()
            }
            .then { session -> Promise<Void> in
                self.klarnaPaymentSession = session
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .then { () -> Promise<Response.Body.Klarna.CustomerToken> in
                return self.authorizePaymentSession(authorizationToken: self.authorizationToken!)
            }
            .done { klarnaCustomerTokenAPIResponse in
                self.klarnaCustomerTokenAPIResponse = klarnaCustomerTokenAPIResponse
                DispatchQueue.main.async {
                    self.willDismissExternalView?()
                }

                seal.fulfill()
            }
            .ensure {
                self.willDismissExternalView?()
                self.klarnaViewController?.dismiss(animated: true, completion: {
                    self.didDismissExternalView?()
                })

                #if DEBUG
                self.demoThirdPartySDKViewController?.dismiss(animated: true, completion: {
                    self.didDismissExternalView?()
                })
                #endif
            }
            .catch { err in
                seal.reject(err)
            }
            #else
            let err = PrimerError.missingSDK(paymentMethodType: PrimerPaymentMethodType.klarna.rawValue,
                                             sdkName: "KlarnaSDK",
                                             userInfo: ["file": #file,
                                                        "class": "\(Self.self)",
                                                        "function": #function,
                                                        "line": "\(#line)"],
                                             diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            seal.reject(err)
            #endif
        }
    }

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
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                var isMockedBE = false
                #if DEBUG
                if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
                    isMockedBE = true
                }
                #endif

                if !isMockedBE {
                    #if canImport(PrimerKlarnaSDK)
                    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

                    guard let urlSchemeStr = settings.paymentMethodOptions.urlScheme,
                          URL(string: urlSchemeStr) != nil else {
                        let err = PrimerError.invalidUrlScheme(
                            urlScheme: settings.paymentMethodOptions.urlScheme,
                            userInfo: ["file": #file,
                                       "class": "\(Self.self)",
                                       "function": #function,
                                       "line": "\(#line)"],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }

                    self.klarnaViewController = PrimerKlarnaViewController(
                        delegate: self,
                        paymentCategory: .payNow,
                        clientToken: self.klarnaPaymentSession!.clientToken,
                        urlScheme: urlSchemeStr)

                    self.klarnaPaymentSessionCompletion = { _, err in
                        if let err = err {
                            seal.reject(err)
                        } else {
                            fatalError()
                        }
                    }

                    self.willPresentExternalView?()
                    PrimerUIManager.primerRootViewController?.show(viewController: self.klarnaViewController!)
                    self.didPresentExternalView?()
                    seal.fulfill()
                    #else
                    seal.fulfill()
                    #endif
                } else {
                    #if DEBUG
                    firstly {
                        PrimerUIManager.prepareRootViewController()
                    }
                    .done {
                        self.demoThirdPartySDKViewController = PrimerThirdPartySDKViewController(paymentMethodType: self.config.type)
                        self.demoThirdPartySDKViewController!.onSendCredentialsButtonTapped = {
                            self.klarnaPaymentSessionCompletion?("mock_auth_token", nil)
                        }
                        PrimerUIManager.primerRootViewController?.present(self.demoThirdPartySDKViewController!, animated: true, completion: {
                            seal.fulfill()
                        })
                    }
                    .catch { _ in
                        seal.fulfill()
                    }
                    #endif
                }
            }
        }
    }

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.klarnaPaymentSessionCompletion = { authorizationToken, err in
                if let err = err {
                    seal.reject(err)
                } else if let authorizationToken = authorizationToken {
                    self.authorizationToken = authorizationToken
                    seal.fulfill()
                } else {
                    precondition(false, "Should never end up in here")
                }
            }
        }
    }

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let klarnaCustomerToken = self.klarnaCustomerTokenAPIResponse?.customerTokenId else {
                let err = PrimerError.invalidValue(key: "tokenization.klarnaCustomerToken", value: nil, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let sessionData = self.klarnaCustomerTokenAPIResponse?.sessionData else {
                let err = PrimerError.invalidValue(key: "tokenization.sessionData", value: nil, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
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
            .catch { err in
                seal.reject(err)
            }
        }
    }

    private func createPaymentSession() -> Promise<Response.Body.Klarna.PaymentSession> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                    "class": "\(Self.self)",
                                                                    "function": #function,
                                                                    "line": "\(#line)"],
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let configId = config.id else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file,
                                                                            "class": "\(Self.self)",
                                                                            "function": #function,
                                                                            "line": "\(#line)"],
                                                                 diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let klarnaSessionType: KlarnaSessionType = PrimerInternal.shared.intent == .vault ? .recurringPayment : .oneOffPayment

            var amount = AppState.current.amount
            if amount == nil && PrimerInternal.shared.intent == .checkout {
                let err = PrimerError.invalidSetting(name: "amount",
                                                     value: nil,
                                                     userInfo: ["file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"],
                                                     diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            //                This is not being used?
            //            var orderItems: [OrderItem]? = nil

            if case .oneOffPayment = klarnaSessionType {
                if amount == nil {
                    let err = PrimerError.invalidSetting(name: "amount",
                                                         value: nil,
                                                         userInfo: ["file": #file,
                                                                    "class": "\(Self.self)",
                                                                    "function": #function,
                                                                    "line": "\(#line)"],
                                                         diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                if AppState.current.currency == nil {
                    let err = PrimerError.invalidSetting(name: "currency",
                                                         value: nil,
                                                         userInfo: ["file": #file,
                                                                    "class": "\(Self.self)",
                                                                    "function": #function,
                                                                    "line": "\(#line)"],
                                                         diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                if (PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.lineItems ?? []).isEmpty {
                    let err = PrimerError.invalidValue(key: "settings.orderItems",
                                                       value: nil,
                                                       userInfo: ["file": #file,
                                                                  "class": "\(Self.self)",
                                                                  "function": #function,
                                                                  "line": "\(#line)"],
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                if !(PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.lineItems ?? []).filter({ $0.amount == nil }).isEmpty {
                    let err = PrimerError.invalidValue(key: "settings.orderItems.amount",
                                                       value: nil,
                                                       userInfo: ["file": #file,
                                                                  "class": "\(Self.self)",
                                                                  "function": #function,
                                                                  "line": "\(#line)"],
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                //                This is not being used?
                //                orderItems = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.lineItems?.compactMap({ try? $0.toOrderItem() })
                //
                self.logger.info(message: "Klarna amount: \(amount!) \(AppState.current.currency!.code)")

            } else if case .recurringPayment = klarnaSessionType {
                // Do not send amount for recurring payments, even if it's set
                amount = nil
            }

            let clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            let countryCode = clientSession?.order?.countryCode?.rawValue ?? ""
            let currencyCode = clientSession?.order?.currencyCode?.code ?? ""
            let localeCode = PrimerSettings.current.localeData.localeCode
            let localeData = Request.Body.Klarna.KlarnaLocaleData(
                countryCode: countryCode,
                currencyCode: currencyCode,
                localeCode: localeCode)

            let body = Request.Body.Klarna.CreatePaymentSession(
                paymentMethodConfigId: configId,
                sessionType: .recurringPayment,
                localeData: localeData,
                description: PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
                redirectUrl: settings.paymentMethodOptions.urlScheme,
                totalAmount: nil,
                orderItems: nil,
                billingAddress: nil,
                shippingAddress: nil)

            let apiClient: PrimerAPIClientProtocol = PaymentMethodTokenizationViewModel.apiClient ?? PrimerAPIClient()

            apiClient.createKlarnaPaymentSession(clientToken: decodedJWTToken, klarnaCreatePaymentSessionAPIRequest: body) { (result) in
                switch result {
                case .failure(let err):
                    seal.reject(err)

                case .success(let res):
                    self.logger.info(message: "\(res)")
                    seal.fulfill(res)
                }
            }
        }
    }

    private func authorizePaymentSession(authorizationToken: String) -> Promise<Response.Body.Klarna.CustomerToken> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                    "class": "\(Self.self)",
                                                                    "function": #function,
                                                                    "line": "\(#line)"],
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let configId = PrimerAPIConfigurationModule.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.klarna.rawValue),
                  let sessionId = self.klarnaPaymentSession?.sessionId else {
                let err = PrimerError.missingPrimerConfiguration(
                    userInfo: ["file": #file,
                               "class": "\(Self.self)",
                               "function": #function,
                               "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
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
                case .failure(let err):
                    seal.reject(err)
                case .success(let response):
                    seal.fulfill(response)
                }
            }
        }
    }

    private func finalizePaymentSession() -> Promise<Response.Body.Klarna.CustomerToken> {
        return Promise { seal in
            self.finalizePaymentSession { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let res):
                    seal.fulfill(res)
                }
            }
        }
    }

    private func finalizePaymentSession(completion: @escaping (Result<Response.Body.Klarna.CustomerToken, Error>) -> Void) {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"],
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        guard let configId = PrimerAPIConfigurationModule.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.klarna.rawValue),
              let sessionId = self.klarnaPaymentSession?.sessionId else {
            let err = PrimerError.missingPrimerConfiguration(
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }

        let body = Request.Body.Klarna.FinalizePaymentSession(paymentMethodConfigId: configId, sessionId: sessionId)
        self.logger.info(message: "config ID: \(configId)")

        let apiClient: PrimerAPIClientProtocol = PaymentMethodTokenizationViewModel.apiClient ?? PrimerAPIClient()

        apiClient.finalizeKlarnaPaymentSession(clientToken: decodedJWTToken, klarnaFinalizePaymentSessionRequest: body) { (result) in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let response):
                self.logger.info(message: "\(response)")
                completion(.success(response))
            }
        }
    }
}

#if canImport(PrimerKlarnaSDK)
extension KlarnaTokenizationViewModel: PrimerKlarnaViewControllerDelegate {

    func primerKlarnaViewDidLoad() {

    }

    func primerKlarnaPaymentSessionCompleted(authorizationToken: String?, error: PrimerKlarnaError?) {
        self.klarnaPaymentSessionCompletion?(authorizationToken, error)
        self.klarnaPaymentSessionCompletion = nil
    }
}
#endif
// swiftlint:enable cyclomatic_complexity
