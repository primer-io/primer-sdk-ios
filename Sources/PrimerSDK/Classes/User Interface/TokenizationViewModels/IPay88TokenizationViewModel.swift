//
//  IPay88TokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos on 12/12/22.
//

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable line_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import Foundation
import UIKit

#if canImport(PrimerIPay88MYSDK)
import PrimerIPay88MYSDK
#endif

final class IPay88TokenizationViewModel: PaymentMethodTokenizationViewModel {

    #if canImport(PrimerIPay88MYSDK)
    private var backendCallbackUrl: URL!
    private var primerTransactionId: String!
    private var statusUrl: URL!
    private var resumeToken: String!
    private var primerIPay88ViewController: PrimerIPay88ViewController!
    private var primerIPay88Payment: PrimerIPay88Payment!
    private var didComplete: (() -> Void)?
    private var didFail: ((_ err: PrimerError) -> Void)?
    private var iPay88PaymentMethodId: String?
    private var iPay88ActionType: String?
    #endif

    #if DEBUG
    private var demoThirdPartySDKViewController: PrimerThirdPartySDKViewController?
    #endif

    private lazy var iPay88NumberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.decimalSeparator = "."
        numberFormatter.groupingSeparator = ","
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        return numberFormatter
    }()

    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            throw handled(primerError: .invalidClientToken())
        }

        guard decodedJWTToken.pciUrl != nil else {
            throw handled(primerError: .invalidClientToken())
        }

        var errors: [PrimerError] = []

        // Merchant info

        if config.id == nil {
            errors.append(PrimerError.invalidValue(key: "configuration.id"))
        }

        if (config.options as? MerchantOptions)?.merchantId == nil {
            errors.append(PrimerError.invalidValue(key: "configuration.merchantId"))
        }

        // Amount & currency validation

        if (AppState.current.amount ?? 0) == 0 {
            errors.append(PrimerError.invalidClientSessionValue(
                name: "amount",
                value: AppState.current.amount.map(String.init)
            ))
        }

        // Order validation

        if (PrimerAPIConfiguration.current?.clientSession?.order?.lineItems ?? []).isEmpty {
            errors.append(PrimerError.invalidClientSessionValue(name: "order.lineItems"))
        } else {
            let productsDescription = PrimerAPIConfiguration.current?.clientSession?.order?.lineItems?
                .compactMap { $0.name ?? $0.description }
                .joined(separator: ", ")

            if productsDescription == nil {
                errors.append(PrimerError.invalidClientSessionValue(name: "order.lineItems.description"))
            }
        }

        // Customer validation

        if PrimerAPIConfiguration.current?.clientSession?.customer?.firstName == nil {
            errors.append(PrimerError.invalidClientSessionValue(name: "customer.firstName"))
        }

        if PrimerAPIConfiguration.current?.clientSession?.customer?.lastName == nil {
            errors.append(PrimerError.invalidClientSessionValue(name: "customer.lastName"))
        }

        if PrimerAPIConfiguration.current?.clientSession?.customer?.emailAddress == nil {
            errors.append(PrimerError.invalidClientSessionValue(name: "customer.emailAddress"))
        }

        #if !canImport(PrimerIPay88MYSDK)
        errors.append(PrimerError.missingSDK(
            paymentMethodType: config.type,
            sdkName: "PrimerIPay88SDK"
        ))
        #endif

        guard errors.isEmpty else {
            let aggregatedError = errors.count == 1 ? errors.first! : PrimerError.underlyingErrors(errors: errors)
            throw handled(primerError: aggregatedError)
        }
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        let imageView = self.uiModule.makeIconImageView(withDimension: 24.0)
        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imageView, message: nil)

        return Promise { seal in
            #if canImport(PrimerIPay88MYSDK)
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
            .done {
                seal.fulfill()
            }
            .ensure {

            }
            .catch { err in
                seal.reject(err)
            }

            #else
            seal.reject(handled(primerError: .missingSDK(paymentMethodType: config.type, sdkName: "PrimerIPay88SDK")))
            #endif
        }
    }

    override func performPreTokenizationSteps() async throws {
        await PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(
            imageView: uiModule.makeIconImageView(withDimension: 24.0),
            message: nil
        )

        #if canImport(PrimerIPay88MYSDK)
        try validate()
        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule.selectPaymentMethodIfNeeded(config.type, cardNetwork: nil)
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
        #else
        throw handled(primerError: .missingSDK(paymentMethodType: config.type, sdkName: "PrimerIPay88SDK"))
        #endif
    }

    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            #if canImport(PrimerIPay88MYSDK)
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

            #else
            seal.reject(handled(primerError: .missingSDK(paymentMethodType: config.type, sdkName: "PrimerIPay88SDK")))
            #endif
        }
    }

    override func performTokenizationStep() async throws {
        #if canImport(PrimerIPay88MYSDK)
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenize()
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
        #else
        throw handled(primerError: .missingSDK(paymentMethodType: config.type, sdkName: "PrimerIPay88SDK"))
        #endif
    }

    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            #if canImport(PrimerIPay88MYSDK)
            seal.fulfill()

            #else
            seal.reject(handled(primerError: .missingSDK(paymentMethodType: config.type, sdkName: "PrimerIPay88SDK")))
            #endif
        }
    }

    override func performPostTokenizationSteps() async throws {
        #if canImport(PrimerIPay88MYSDK)
        // Empty implementation
        #else
        throw handled(primerError: .missingSDK(paymentMethodType: config.type, sdkName: "PrimerIPay88SDK"))
        #endif
    }

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            #if canImport(PrimerIPay88MYSDK)
            guard let configId = config.id else {
                return seal.reject(handled(primerError: .invalidValue(key: "configuration.id")))
            }

            let sessionInfo = IPay88SessionInfo(refNo: UUID().uuidString, locale: "en-US")

            let paymentInstrument = OffSessionPaymentInstrument(
                paymentMethodConfigId: configId,
                paymentMethodType: config.type,
                sessionInfo: sessionInfo)

            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)

            firstly {
                self.tokenizationService.tokenize(requestBody: requestBody)
            }
            .done { paymentMethod in
                seal.fulfill(paymentMethod)
            }
            .catch { err in
                seal.reject(err)
            }

            #else
            seal.reject(handled(primerError: .missingSDK(paymentMethodType: config.type, sdkName: "PrimerIPay88SDK")))
            #endif
        }
    }

    override func tokenize() async throws -> PrimerPaymentMethodTokenData {
        #if canImport(PrimerIPay88MYSDK)
        guard let configId = config.id else {
            throw handled(primerError: .invalidValue(key: "configuration.id"))
        }

        return try await tokenizationService.tokenize(
            requestBody: Request.Body.Tokenization(
                paymentInstrument: OffSessionPaymentInstrument(
                    paymentMethodConfigId: configId,
                    paymentMethodType: config.type,
                    sessionInfo: IPay88SessionInfo(refNo: UUID().uuidString, locale: "en-US")
                )
            )
        )
        #else
        throw handled(primerError: .missingSDK(paymentMethodType: config.type, sdkName: "PrimerIPay88SDK"))
        #endif
    }

    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                                   paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
        return Promise { seal in
            #if canImport(PrimerIPay88MYSDK)
            if decodedJWTToken.intent == "IPAY88_CARD_REDIRECTION" {
                guard let backendCallbackUrlRawString = decodedJWTToken.backendCallbackUrl,
                      let backendCallbackUrlStr =
                        backendCallbackUrlRawString.addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed)?
                        .replacingOccurrences(of: "=", with: "%3D"),
                      let backendCallbackUrl = URL(string: backendCallbackUrlStr),
                      let statusUrlStr = decodedJWTToken.statusUrl,
                      let statusUrl = URL(string: statusUrlStr),
                      let primerTransactionId = decodedJWTToken.primerTransactionId
                else {
                    return seal.reject(handled(primerError: .invalidClientToken()))
                }

                DispatchQueue.main.async {
                    PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                }

                self.backendCallbackUrl = backendCallbackUrl
                self.primerTransactionId = primerTransactionId
                self.statusUrl = statusUrl

                do {
                    self.primerIPay88Payment = try self.createPrimerIPay88Payment()

                    firstly {
                        self.presentPaymentMethodUserInterface()
                    }
                    .then { () -> Promise<Void> in
                        return self.awaitUserInput()
                    }
                    .done {
                        seal.fulfill(self.resumeToken)
                    }
                    .catch { err in
                        seal.reject(err)
                    }

                } catch {
                    seal.reject(error)
                }

            } else {
                seal.fulfill(nil)
            }

            #else
            seal.reject(handled(primerError: .missingSDK(paymentMethodType: config.type, sdkName: "PrimerIPay88SDK")))
            #endif
        }
    }

    override func handleDecodedClientTokenIfNeeded(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> String? {
        #if canImport(PrimerIPay88MYSDK)
        if decodedJWTToken.intent == "IPAY88_CARD_REDIRECTION" {
            guard let callbackRaw = decodedJWTToken.backendCallbackUrl,
                  let callbackStr = callbackRaw.addingPercentEncoding(
                      withAllowedCharacters: .urlPasswordAllowed
                  )?.replacingOccurrences(of: "=", with: "%3D"),
                  let callbackUrl = URL(string: callbackStr),
                  let statusUrlRaw = decodedJWTToken.statusUrl,
                  let statusUrl = URL(string: statusUrlRaw),
                  let primerTransactionId = decodedJWTToken.primerTransactionId
            else {
                throw handled(primerError: .invalidClientToken())
            }

            await PrimerUIManager.primerRootViewController?.enableUserInteraction(true)

            self.backendCallbackUrl = callbackUrl
            self.primerTransactionId = primerTransactionId
            self.statusUrl = statusUrl

            primerIPay88Payment = try createPrimerIPay88Payment()
            try await presentPaymentMethodUserInterface()
            try await awaitUserInput()
            return resumeToken
        } else {
            return nil
        }
        #else
        throw handled(primerError: .missingSDK(paymentMethodType: config.type, sdkName: "PrimerIPay88SDK"))
        #endif
    }

    #if canImport(PrimerIPay88MYSDK)
    private func createPrimerIPay88Payment() throws -> PrimerIPay88Payment {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
              let primerTransactionId = decodedJWTToken.primerTransactionId,
              let iPay88PaymentMethodId = decodedJWTToken.iPay88PaymentMethodId,
              let supportedCurrency = decodedJWTToken.supportedCurrencyCode,
              supportedCurrency.uppercased() == PrimerAPIConfiguration.current?.clientSession?.order?.currencyCode?.code.uppercased(),
              let supportedCountry = decodedJWTToken.supportedCountry,
              supportedCountry.uppercased() == PrimerAPIConfiguration.current?.clientSession?.order?.countryCode?.rawValue.uppercased()
        else {
            throw handled(primerError: .invalidClientToken())
        }

        let iPay88ActionType = decodedJWTToken.iPay88ActionType ?? ""

        if iPay88ActionType == "BT" && PrimerAPIConfiguration.current?.clientSession?.customer?.id == nil {
            throw handled(primerError: .invalidClientSessionValue(name: "customer.id"))
        }

        self.iPay88PaymentMethodId = iPay88PaymentMethodId
        self.iPay88ActionType = iPay88ActionType

        let amountStr = iPay88NumberFormatter.string(from: NSNumber(value: Double(AppState.current.amount!) / 100)) ?? ""

        guard let merchantOptions = config.options as? MerchantOptions
        else {
            fatalError()
        }

        let primerIPayPayment = PrimerIPay88Payment(
            merchantCode: merchantOptions.merchantId,
            paymentId: iPay88PaymentMethodId,
            refNo: primerTransactionId,
            amount: amountStr,
            currency: supportedCurrency,
            prodDesc: PrimerAPIConfiguration.current!.clientSession!.order!.lineItems!.compactMap { $0.description }.joined(separator: ", "),
            userName: "\(PrimerAPIConfiguration.current!.clientSession!.customer!.firstName!) \(PrimerAPIConfiguration.current!.clientSession!.customer!.lastName!)",
            userEmail: PrimerAPIConfiguration.current!.clientSession!.customer!.emailAddress!,
            userContact: "",
            remark: PrimerAPIConfiguration.current!.clientSession?.customer?.id,
            lang: "UTF-8",
            country: supportedCountry,
            backendPostURL: backendCallbackUrl?.absoluteString ?? "",
            appdeeplink: nil,
            actionType: iPay88ActionType,
            tokenId: nil,
            promoCode: nil,
            fixPaymentId: iPay88PaymentMethodId,
            transId: nil,
            authCode: nil
        )

        return primerIPayPayment
    }

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                var isMockBE = false

                #if DEBUG
                if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
                    isMockBE = true
                }
                #endif

                if !isMockBE {
                    self.primerIPay88ViewController = PrimerIPay88ViewController(delegate: self,
                                                                                 payment: self.primerIPay88Payment!)

                    self.primerIPay88ViewController.isModalInPresentation = true
                    self.primerIPay88ViewController.modalPresentationStyle = .fullScreen

                    let iPay88PresentEvent = Analytics.Event.ui(
                        action: .present,
                        context: Analytics.Event.Property.Context(
                            paymentMethodType: self.config.type,
                            iPay88PaymentMethodId: self.iPay88PaymentMethodId,
                            iPay88ActionType: self.iPay88ActionType),
                        extra: nil,
                        objectType: .view,
                        objectId: nil,
                        objectClass: "\(Self.self)",
                        place: .iPay88View
                    )
                    Analytics.Service.record(event: iPay88PresentEvent)

                    self.willPresentPaymentMethodUI?()

                    let delegate = PrimerHeadlessUniversalCheckout.current.uiDelegate
                    PrimerUIManager.primerRootViewController?.present(self.primerIPay88ViewController,
                                                                      animated: true,
                                                                      completion: {
                                                                        DispatchQueue.main.async {
                                                                            delegate?.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod?(for: self.config.type)
                                                                            self.didPresentPaymentMethodUI?()
                                                                            seal.fulfill()
                                                                        }
                                                                      })

                    self.didComplete = { [unowned self] in
                        DispatchQueue.main.async { [unowned self] in
                            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil,
                                                                                                message: nil)
                            self.primerIPay88ViewController?.dismiss(animated: true, completion: {

                            })
                        }
                    }

                } else {
                    #if DEBUG
                    firstly {
                        PrimerUIManager.prepareRootViewController()
                    }
                    .done {
                        self.demoThirdPartySDKViewController = PrimerThirdPartySDKViewController(paymentMethodType: self.config.type)
                        self.demoThirdPartySDKViewController!.onSendCredentialsButtonTapped = {
                            guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                return seal.reject(handled(primerError: .invalidClientToken()))
                            }

                            let client = PrimerAPIClient()
                            client.testFinalizePolling(clientToken: clientToken,
                                                       testId: PrimerAPIConfiguration.current?.clientSession?.testId ?? "") { _ in

                            }
                        }
                        PrimerUIManager.primerRootViewController?.present(self.demoThirdPartySDKViewController!,
                                                                          animated: true,
                                                                          completion: {
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

    @MainActor
    override func presentPaymentMethodUserInterface() async throws {
        #if DEBUG
        let isMockBE = PrimerAPIConfiguration.current?.clientSession?.testId != nil
        #else
        let isMockBE = false
        #endif

        if !isMockBE {
            let newPrimerIPay88ViewController = PrimerIPay88ViewController(delegate: self, payment: primerIPay88Payment!)
            newPrimerIPay88ViewController.isModalInPresentation = true
            newPrimerIPay88ViewController.modalPresentationStyle = .fullScreen
            primerIPay88ViewController = newPrimerIPay88ViewController

            Analytics.Service.fire(
                event: Analytics.Event.ui(
                    action: .present,
                    context: Analytics.Event.Property.Context(
                        paymentMethodType: config.type,
                        iPay88PaymentMethodId: iPay88PaymentMethodId,
                        iPay88ActionType: iPay88ActionType
                    ),
                    extra: nil,
                    objectType: .view,
                    objectId: nil,
                    objectClass: "\(Self.self)",
                    place: .iPay88View
                )
            )

            willPresentPaymentMethodUI?()
            let delegate = PrimerHeadlessUniversalCheckout.current.uiDelegate

            didComplete = {
                DispatchQueue.main.async {
                    PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
                    newPrimerIPay88ViewController.dismiss(animated: true, completion: nil)
                }
            }

            await withCheckedContinuation { continuation in
                PrimerUIManager.primerRootViewController?.present(newPrimerIPay88ViewController, animated: true) {
                    DispatchQueue.main.async {
                        delegate?.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod?(for: self.config.type)
                        self.didPresentPaymentMethodUI?()
                        continuation.resume()
                    }
                }
            }
        } else {
            #if DEBUG
            PrimerUIManager.prepareRootViewController_main_actor()

            let newPrimerThirdPartySDKViewController = PrimerThirdPartySDKViewController(paymentMethodType: config.type)
            demoThirdPartySDKViewController = newPrimerThirdPartySDKViewController

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                newPrimerThirdPartySDKViewController.onSendCredentialsButtonTapped = {
                    guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                        return continuation.resume(throwing: handled(primerError: .invalidClientToken()))
                    }

                    PrimerAPIClient().testFinalizePolling(
                        clientToken: clientToken,
                        testId: PrimerAPIConfiguration.current?.clientSession?.testId ?? ""
                    ) { _ in
                    }
                }

                PrimerUIManager.primerRootViewController?.present(newPrimerThirdPartySDKViewController, animated: true) {
                    continuation.resume()
                }
            }

            #endif
        }
    }

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            let pollingModule = PollingModule(url: self.statusUrl)
            self.didCancel = {
                pollingModule.cancel(withError: handled(primerError: .cancelled(paymentMethodType: self.config.type)))
            }

            self.didFail = { err in
                pollingModule.fail(withError: err)
            }

            firstly {
                pollingModule.start()
            }
            .done { resumeToken in
                self.resumeToken = resumeToken
                seal.fulfill()
            }
            .ensure {
                let iPay88DismissEvent = Analytics.Event.ui(
                    action: .dismiss,
                    context: Analytics.Event.Property.Context(
                        paymentMethodType: self.config.type,
                        iPay88PaymentMethodId: self.iPay88PaymentMethodId,
                        iPay88ActionType: self.iPay88ActionType),
                    extra: nil,
                    objectType: .view,
                    objectId: nil,
                    objectClass: "\(Self.self)",
                    place: .iPay88View
                )
                Analytics.Service.record(event: iPay88DismissEvent)

                DispatchQueue.main.async { [unowned self] in
                    var isMockBE = false

                    #if DEBUG
                    if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
                        isMockBE = true
                    }
                    #endif

                    if !isMockBE {
                        self.primerIPay88ViewController?.dismiss(animated: true)
                    } else {
                        #if DEBUG
                        self.demoThirdPartySDKViewController?.dismiss(animated: true)
                        #endif
                    }
                }
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func awaitUserInput() async throws {
        let pollingModule = PollingModule(url: statusUrl)
        didCancel = {
            let err = PrimerError.cancelled(
                paymentMethodType: self.config.type,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: err)
            pollingModule.cancel(withError: err)
        }

        didFail = { err in
            pollingModule.fail(withError: err)
        }

        defer {
            Analytics.Service.fire(event: Analytics.Event.ui(
                action: .dismiss,
                context: Analytics.Event.Property.Context(
                    paymentMethodType: self.config.type,
                    iPay88PaymentMethodId: self.iPay88PaymentMethodId,
                    iPay88ActionType: self.iPay88ActionType
                ),
                extra: nil,
                objectType: .view,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .iPay88View
            ))

            DispatchQueue.main.async {
                #if DEBUG
                let isMockBE = PrimerAPIConfiguration.current?.clientSession?.testId != nil
                #else
                let isMockBE = false
                #endif

                if !isMockBE {
                    self.primerIPay88ViewController?.dismiss(animated: true)
                } else {
                    #if DEBUG
                    self.demoThirdPartySDKViewController?.dismiss(animated: true)
                    #endif
                }
            }
        }

        resumeToken = try await pollingModule.start()
    }

    func nullifyCallbacks() {
        didCancel = nil
        didComplete = nil
        didFail = nil
    }
    #endif
}

#if canImport(PrimerIPay88MYSDK)
extension IPay88TokenizationViewModel: PrimerIPay88ViewControllerDelegate {
    func primerIPay88ViewDidLoad() {}

    func primerIPay88PaymentSessionCompleted(payment: PrimerIPay88MYSDK.PrimerIPay88Payment?,
                                             error: PrimerIPay88MYSDK.PrimerIPay88Error?) {
        if let payment {
            primerIPay88Payment = payment
        }

        if let error = error {
            switch error {
            case .iPay88Error(let description, _):
                didFail?(handled(primerError: .failedToCreatePayment(
                    paymentMethodType: PrimerPaymentMethodType.iPay88Card.rawValue,
                    description: "iPay88 payment (transId: \(primerIPay88Payment.transId ?? "nil"), refNo: \(primerIPay88Payment.refNo) failed with error '\(description)'"
                )))
                nullifyCallbacks()
            }
        } else {
            didComplete?()
            nullifyCallbacks()
        }
    }

    func primerIPay88PaymentCancelled(payment: PrimerIPay88MYSDK.PrimerIPay88Payment?, error: PrimerIPay88MYSDK.PrimerIPay88Error?) {
        didCancel?()
        nullifyCallbacks()
    }
}
#endif
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable line_length
// swiftlint:enable file_length
