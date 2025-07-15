// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import UIKit
import AuthenticationServices
import SafariServices

final class PayPalTokenizationViewModel: PaymentMethodTokenizationViewModel {

    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?

    private var payPalUrl: URL!
    private var payPalInstrument: PayPalPaymentInstrument!
    private var session: Any!
    private var orderId: String?
    private var confirmBillingAgreementResponse: Response.Body.PayPal.ConfirmBillingAgreement?

    lazy var webAuthenticationService: WebAuthenticationService = {
        DefaultWebAuthenticationService()
    }()

    lazy var payPalService: PayPalServiceProtocol = {
        PayPalService()
    }()

    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard decodedJWTToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl",
                                               value: decodedJWTToken.pciUrl,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id",
                                               value: config.id,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard decodedJWTToken.coreUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.coreUrl",
                                               value: decodedJWTToken.pciUrl,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }
    
    override func start() {
        self.didPresentExternalView = { [weak self] in
            if let strongSelf = self {
                PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: strongSelf.config.type)
            }
        }

        super.start()
    }

    override func start_async() {
        self.didPresentExternalView = { [weak self] in
            if let strongSelf = self {
                PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: strongSelf.config.type)
            }
        }

        super.start_async()
    }

    override func performPreTokenizationSteps() -> Promise<Void> {

        DispatchQueue.main.async {
            PrimerUIManager.primerRootViewController?.enableUserInteraction(false)
        }

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

        let imageView = self.uiModule.makeIconImageView(withDimension: 24.0)
        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imageView,
                                                                            message: nil)

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
            .then { () -> Promise<Void> in
                self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func performPreTokenizationSteps() async throws {
        DispatchQueue.main.async {
            PrimerUIManager.primerRootViewController?.enableUserInteraction(false)
        }

        let event = Analytics.Event.ui(
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

        try await Analytics.Service.record(event: event)
        await PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(
            imageView: self.uiModule.makeIconImageView(withDimension: 24.0),
            message: nil
        )
        try validate()

        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
        try await presentPaymentMethodUserInterface()
        try await awaitUserInput()
    }

    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: self.config.type)

            firstly {
                self.checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func performTokenizationStep() async throws {
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: self.config.type)
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        let paymentMethodTokenData = try await tokenize()
        self.paymentMethodTokenData = paymentMethodTokenData
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    override func performPostTokenizationSteps() async throws {}

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.fetchOAuthURL()
            }
            .then { url -> Promise<URL> in
                self.willPresentExternalView?()
                return self.createOAuthSession(url)
            }
            .done { _  in
                self.didPresentExternalView?()
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func presentPaymentMethodUserInterface() async throws {
        let url = try await fetchOAuthURL()
        willPresentExternalView?()
        _ = try await createOAuthSession(url)
        didPresentExternalView?()
    }

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.createPaypalPaymentInstrument()
            }
            .done { instrument in
                self.payPalInstrument = instrument
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func awaitUserInput() async throws {
        let instrument = try await createPaypalPaymentInstrument()
        self.payPalInstrument = instrument
    }

    private func fetchOAuthURL() -> Promise<URL> {
        return Promise { seal in

            switch PrimerInternal.shared.intent {
            case .checkout:
                payPalService.startOrderSession { result in
                    switch result {
                    case .success(let res):
                        guard let url = URL(string: res.approvalUrl) else {
                            let err = PrimerError.invalidValue(key: "res.approvalUrl",
                                                               value: res.approvalUrl,
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }

                        self.orderId = res.orderId
                        seal.fulfill(url)

                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            case .vault:
                payPalService.startBillingAgreementSession { result in
                    switch result {
                    case .success(let urlStr):
                        guard let url = URL(string: urlStr) else {
                            let err = PrimerError.invalidValue(key: "billingAgreement.response.url",
                                                               value: urlStr,
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }

                        seal.fulfill(url)

                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            case .none:
                assert(true, "Intent should already be set")
            }
        }
    }

    private func fetchOAuthURL() async throws -> URL {
        switch PrimerInternal.shared.intent {
        case .checkout:
            let res = try await payPalService.startOrderSession()
            guard let url = URL(string: res.approvalUrl) else {
                let err = PrimerError.invalidValue(key: "res.approvalUrl",
                                                   value: res.approvalUrl,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            self.orderId = res.orderId
            return url
        case .vault:
            let urlStr = try await payPalService.startBillingAgreementSession()
            guard let url = URL(string: urlStr) else {
                let err = PrimerError.invalidValue(key: "billingAgreement.response.url",
                                                   value: urlStr,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            return url
        case .none:
            preconditionFailure("Intent should already be set")
        }
    }

    private func createOAuthSession(_ url: URL) -> Promise<URL> {
        return Promise { seal in
            var scheme: String
            do {
                scheme = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
            } catch let error {
                seal.reject(error)
                return
            }

            webAuthenticationService.connect(paymentMethodType: self.config.type, url: url, scheme: scheme) { [weak self] result in
                switch result {
                case .success(let url):
                    seal.fulfill(url)
                case .failure(let error):
                    seal.reject(error)
                }
                self?.webAuthenticationService.session?.cancel()
            }
        }
    }

    private func createOAuthSession(_ url: URL) async throws -> URL {
        let scheme = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
        let oauthUrl = try await webAuthenticationService.connect(paymentMethodType: self.config.type, url: url, scheme: scheme)
        webAuthenticationService.session?.cancel()
        return oauthUrl
    }

    func fetchPayPalExternalPayerInfo(orderId: String) -> Promise<Response.Body.PayPal.PayerInfo> {
        return Promise { seal in
            payPalService.fetchPayPalExternalPayerInfo(orderId: orderId) { result in
                switch result {
                case .success(let response):
                    seal.fulfill(response)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }

    func fetchPayPalExternalPayerInfo(orderId: String) async throws -> Response.Body.PayPal.PayerInfo {
        try await payPalService.fetchPayPalExternalPayerInfo(orderId: orderId)
    }

    private func createPaypalPaymentInstrument() -> Promise<PayPalPaymentInstrument> {
        return Promise { seal in
            if PrimerInternal.shared.intent == .vault {
                firstly {
                    self.generateBillingAgreementConfirmation()
                }
                .done { billingAgreement in
                    let paymentInstrument = PayPalPaymentInstrument(
                        paypalOrderId: nil,
                        paypalBillingAgreementId: billingAgreement.billingAgreementId,
                        shippingAddress: billingAgreement.shippingAddress,
                        externalPayerInfo: billingAgreement.externalPayerInfo)

                    seal.fulfill(paymentInstrument)
                }
                .catch { err in
                    seal.reject(err)
                }
            } else {
                guard let orderId = orderId else {
                    let err = PrimerError.invalidValue(key: "orderId",
                                                       value: orderId,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                firstly {
                    self.fetchPayPalExternalPayerInfo(orderId: orderId)
                }
                .then { res -> Promise<PayPalPaymentInstrument> in
                    return self.generatePaypalPaymentInstrument(externalPayerInfo: res.externalPayerInfo)
                }
                .done { response in
                    self.generatePaypalPaymentInstrument(externalPayerInfo: response.externalPayerInfo) { result in
                        switch result {
                        case .success(let paymentInstrument):
                            seal.fulfill(paymentInstrument)
                        case .failure(let err):
                            seal.reject(err)
                        }
                    }
                }
                .catch { err in
                    seal.reject(err)
                }
            }

        }
    }

    private func createPaypalPaymentInstrument() async throws -> PayPalPaymentInstrument {
        if PrimerInternal.shared.intent == .vault {
            let billingAgreement = try await generateBillingAgreementConfirmation()
            return PayPalPaymentInstrument(
                paypalOrderId: nil,
                paypalBillingAgreementId: billingAgreement.billingAgreementId,
                shippingAddress: billingAgreement.shippingAddress,
                externalPayerInfo: billingAgreement.externalPayerInfo
            )
        } else {
            guard let orderId = orderId else {
                let err = PrimerError.invalidValue(key: "orderId",
                                                   value: orderId,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            let response = try await fetchPayPalExternalPayerInfo(orderId: orderId)

            // MARK: REVIEW_CHECK: Is this correct? because PromiseKit version is using 'generatePaypalPaymentInstrument' twice

            return try await generatePaypalPaymentInstrument(externalPayerInfo: response.externalPayerInfo)
        }
    }

    private func generatePaypalPaymentInstrument(externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo?) -> Promise<PayPalPaymentInstrument> {
        return Promise { seal in
            self.generatePaypalPaymentInstrument(externalPayerInfo: externalPayerInfo) { result in
                switch result {
                case .success(let paymentInstrument):
                    seal.fulfill(paymentInstrument)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }

    private func generatePaypalPaymentInstrument(
        externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo?
    ) async throws -> PayPalPaymentInstrument {
        switch PrimerInternal.shared.intent {
        case .checkout:
            guard let orderId = orderId else {
                let err = PrimerError.invalidValue(key: "orderId",
                                                   value: orderId,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            guard let externalPayerInfo = externalPayerInfo else {
                let err = PrimerError.invalidValue(key: "externalPayerInfo",
                                                   value: orderId,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            return PayPalPaymentInstrument(
                paypalOrderId: orderId,
                paypalBillingAgreementId: nil,
                shippingAddress: nil,
                externalPayerInfo: externalPayerInfo
            )
        case .vault:
            guard let confirmedBillingAgreement = self.confirmBillingAgreementResponse else {
                let err = PrimerError.invalidValue(key: "confirmedBillingAgreement",
                                                   value: orderId,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            return PayPalPaymentInstrument(
                paypalOrderId: nil,
                paypalBillingAgreementId: confirmedBillingAgreement.billingAgreementId,
                shippingAddress: confirmedBillingAgreement.shippingAddress,
                externalPayerInfo: confirmedBillingAgreement.externalPayerInfo
            )
        case .none:
            preconditionFailure("Intent should already be set")
        }
    }

    private func generatePaypalPaymentInstrument(externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo?, completion: @escaping (Result<PayPalPaymentInstrument, Error>) -> Void) {
        switch PrimerInternal.shared.intent {
        case .checkout:
            guard let orderId = orderId else {
                let err = PrimerError.invalidValue(key: "orderId",
                                                   value: orderId,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }

            guard let externalPayerInfo = externalPayerInfo else {
                let err = PrimerError.invalidValue(key: "externalPayerInfo",
                                                   value: orderId,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }

            let paymentInstrument = PayPalPaymentInstrument(
                paypalOrderId: orderId,
                paypalBillingAgreementId: nil,
                shippingAddress: nil,
                externalPayerInfo: externalPayerInfo)

            completion(.success(paymentInstrument))

        case .vault:
            guard let confirmedBillingAgreement = self.confirmBillingAgreementResponse else {
                let err = PrimerError.invalidValue(key: "confirmedBillingAgreement",
                                                   value: orderId,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            let paymentInstrument = PayPalPaymentInstrument(
                paypalOrderId: nil,
                paypalBillingAgreementId: confirmedBillingAgreement.billingAgreementId,
                shippingAddress: confirmedBillingAgreement.shippingAddress,
                externalPayerInfo: confirmedBillingAgreement.externalPayerInfo)

            completion(.success(paymentInstrument))

        case .none:
            assert(true, "Intent should have been set.")
        }
    }

    private func generateBillingAgreementConfirmation() -> Promise<Response.Body.PayPal.ConfirmBillingAgreement> {
        return Promise { seal in
            self.generateBillingAgreementConfirmation { [unowned self] (billingAgreementRes, err) in
                if let err = err {
                    seal.reject(err)
                } else if let billingAgreementRes = billingAgreementRes {
                    self.confirmBillingAgreementResponse = billingAgreementRes
                    seal.fulfill(billingAgreementRes)
                }
            }
        }
    }

    private func generateBillingAgreementConfirmation() async throws -> Response.Body.PayPal.ConfirmBillingAgreement {
        do {
            let res = try await payPalService.confirmBillingAgreement()
            self.confirmBillingAgreementResponse = res
            return res
        } catch {
            let err = PrimerError.failedToCreateSession(error: error,
                                                        userInfo: .errorUserInfoDictionary(),
                                                        diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }

    private func generateBillingAgreementConfirmation(_ completion: @escaping (Response.Body.PayPal.ConfirmBillingAgreement?, Error?) -> Void) {

        payPalService.confirmBillingAgreement({ result in
            switch result {
            case .failure(let err):
                let contaiinerErr = PrimerError.failedToCreateSession(error: err,
                                                                      userInfo: .errorUserInfoDictionary(),
                                                                      diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                completion(nil, contaiinerErr)
            case .success(let res):
                self.confirmBillingAgreementResponse = res
                completion(res, nil)
            }
        })
    }

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        let requestBody = Request.Body.Tokenization(paymentInstrument: self.payPalInstrument)
        return tokenizationService.tokenize(requestBody: requestBody)
    }

    override func tokenize() async throws -> PrimerPaymentMethodTokenData {
        try await tokenizationService.tokenize(
            requestBody: Request.Body.Tokenization(paymentInstrument: self.payPalInstrument)
        )
    }
}
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable file_length
