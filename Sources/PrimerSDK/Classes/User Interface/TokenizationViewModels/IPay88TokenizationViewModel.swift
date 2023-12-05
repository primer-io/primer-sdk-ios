//
//  IPay88TokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos on 12/12/22.
//

import Foundation
import UIKit

#if canImport(PrimerIPay88MYSDK)
import PrimerIPay88MYSDK
#endif

class IPay88TokenizationViewModel: PaymentMethodTokenizationViewModel {

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
            let err = PrimerError.invalidClientToken(
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
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

        var errors: [PrimerError] = []

        // Merchant info

        if self.config.id == nil {
            let err = PrimerError.invalidValue(
                key: "configuration.id",
                value: config.id,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }

        if (self.config.options as? MerchantOptions)?.merchantId == nil {
            let err = PrimerError.invalidValue(
                key: "configuration.merchantId",
                value: config.id,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }

        // Amount & currency validation

        if (AppState.current.amount ?? 0) == 0 {
            let err = PrimerError.invalidClientSessionValue(
                name: "amount",
                value: AppState.current.amount == nil ? nil : "\(AppState.current.amount!)",
                allowedValue: nil,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }

        // Order validation

        if (PrimerAPIConfiguration.current?.clientSession?.order?.lineItems ?? []).count == 0 {
            let err = PrimerError.invalidClientSessionValue(
                name: "order.lineItems",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            errors.append(err)

        } else {
            let productsDescription = PrimerAPIConfiguration.current?.clientSession?.order?.lineItems?.compactMap({ $0.name ?? $0.description }).joined(separator: ", ")

            if productsDescription == nil {
                let err = PrimerError.invalidClientSessionValue(
                    name: "order.lineItems.description",
                    value: nil,
                    allowedValue: nil,
                    userInfo: ["file": #file,
                               "class": "\(Self.self)",
                               "function": #function,
                               "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                errors.append(err)
            }
        }

        // Customer validation

        if PrimerAPIConfiguration.current?.clientSession?.customer?.firstName == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "customer.firstName",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }

        if PrimerAPIConfiguration.current?.clientSession?.customer?.lastName == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "customer.lastName",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }

        if PrimerAPIConfiguration.current?.clientSession?.customer?.emailAddress == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "customer.emailAddress",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }

#if !canImport(PrimerIPay88MYSDK)
        let err = PrimerError.missingSDK(
            paymentMethodType: self.config.type,
            sdkName: "PrimerIPay88SDK",
            userInfo: ["file": #file,
                       "class": "\(Self.self)",
                       "function": #function,
                       "line": "\(#line)"],
            diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: err)
        errors.append(err)
#endif

        if errors.count == 1 {
            throw errors.first!

        } else if errors.count > 1 {
            let err = PrimerError.underlyingErrors(
                errors: errors,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: self.uiModule.makeIconImageView(withDimension: 24.0), message: nil)

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
            let err = PrimerError.missingSDK(
                paymentMethodType: self.config.type,
                sdkName: "PrimerIPay88SDK",
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
#if canImport(PrimerIPay88MYSDK)
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: self.config.type)

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

#else
            let err = PrimerError.missingSDK(
                paymentMethodType: self.config.type,
                sdkName: "PrimerIPay88SDK",
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

    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
#if canImport(PrimerIPay88MYSDK)
            seal.fulfill()

#else
            let err = PrimerError.missingSDK(
                paymentMethodType: self.config.type,
                sdkName: "PrimerIPay88SDK",
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

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
#if canImport(PrimerIPay88MYSDK)
            guard let configId = config.id else {
                let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file,
                                                                                                         "class": "\(Self.self)",
                                                                                                         "function": #function,
                                                                                                         "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let sessionInfo = IPay88SessionInfo(refNo: UUID().uuidString, locale: "en-US")

            let paymentInstrument = OffSessionPaymentInstrument(
                paymentMethodConfigId: configId,
                paymentMethodType: config.type,
                sessionInfo: sessionInfo)

            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()

            firstly {
                tokenizationService.tokenize(requestBody: requestBody)
            }
            .done { paymentMethod in
                seal.fulfill(paymentMethod)
            }
            .catch { err in
                seal.reject(err)
            }

#else
            let err = PrimerError.missingSDK(
                paymentMethodType: self.config.type,
                sdkName: "PrimerIPay88SDK",
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

    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
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
                    let err = PrimerError.invalidClientToken(
                        userInfo: ["file": #file,
                                   "class": "\(Self.self)",
                                   "function": #function,
                                   "line": "\(#line)"],
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
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
            let err = PrimerError.missingSDK(
                paymentMethodType: self.config.type,
                sdkName: "PrimerIPay88SDK",
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

#if canImport(PrimerIPay88MYSDK)
    internal func createPrimerIPay88Payment() throws -> PrimerIPay88Payment {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
              let primerTransactionId = decodedJWTToken.primerTransactionId,
              let iPay88PaymentMethodId = decodedJWTToken.iPay88PaymentMethodId,
              let supportedCurrency = decodedJWTToken.supportedCurrencyCode,
              supportedCurrency.uppercased() == PrimerAPIConfiguration.current?.clientSession?.order?.currencyCode?.rawValue.uppercased(),
              let supportedCountry = decodedJWTToken.supportedCountry,
              supportedCountry.uppercased() == PrimerAPIConfiguration.current?.clientSession?.order?.countryCode?.rawValue.uppercased()
        else {
            let err = PrimerError.invalidClientToken(
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        let iPay88ActionType = decodedJWTToken.iPay88ActionType ?? ""

        if iPay88ActionType == "BT" && PrimerAPIConfiguration.current?.clientSession?.customer?.id == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "customer.id",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file,
                           "class": "\(Self.self)",
                           "function": #function,
                           "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        self.iPay88PaymentMethodId = iPay88PaymentMethodId
        self.iPay88ActionType = iPay88ActionType

        let amountStr = self.iPay88NumberFormatter.string(from: NSNumber(value: Double(AppState.current.amount!)/100)) ?? ""

        guard let merchantOptions = self.config.options as? MerchantOptions
        else {
            fatalError()
        }

        let primerIPayPayment = PrimerIPay88Payment(
            merchantCode: merchantOptions.merchantId,
            paymentId: iPay88PaymentMethodId,
            refNo: primerTransactionId,
            amount: amountStr,
            currency: supportedCurrency,
            prodDesc: PrimerAPIConfiguration.current!.clientSession!.order!.lineItems!.compactMap({ $0.description }).joined(separator: ", "),
            userName: "\(PrimerAPIConfiguration.current!.clientSession!.customer!.firstName!) \(PrimerAPIConfiguration.current!.clientSession!.customer!.lastName!)",
            userEmail: PrimerAPIConfiguration.current!.clientSession!.customer!.emailAddress!,
            userContact: "",
            remark: PrimerAPIConfiguration.current!.clientSession?.customer?.id,
            lang: "UTF-8",
            country: supportedCountry,
            backendPostURL: self.backendCallbackUrl?.absoluteString ?? "",
            appdeeplink: nil,
            actionType: iPay88ActionType,
            tokenId: nil,
            promoCode: nil,
            fixPaymentId: iPay88PaymentMethodId,
            transId: nil,
            authCode: nil)

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

                    PrimerUIManager.primerRootViewController?.present(self.primerIPay88ViewController,
                                                                      animated: true,
                                                                      completion: {
                        DispatchQueue.main.async {
                            PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod?(for: self.config.type)
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
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                                    "class": "\(Self.self)",
                                                                                    "function": #function,
                                                                                    "line": "\(#line)"],
                                                                         diagnosticsId: UUID().uuidString)
                                ErrorHandler.handle(error: err)
                                seal.reject(err)
                                return
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

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            let pollingModule = PollingModule(url: self.statusUrl)
            self.didCancel = {
                let err = PrimerError.cancelled(
                    paymentMethodType: self.config.type,
                    userInfo: ["file": #file,
                               "class": "\(Self.self)",
                               "function": #function,
                               "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                pollingModule.cancel(withError: err)
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

    func nullifyCallbacks() {
        self.didCancel = nil
        self.didComplete = nil
        self.didFail = nil
    }
#endif
}

#if canImport(PrimerIPay88MYSDK)
extension IPay88TokenizationViewModel: PrimerIPay88ViewControllerDelegate {

    func primerIPay88ViewDidLoad() {

    }

    func primerIPay88PaymentSessionCompleted(payment: PrimerIPay88MYSDK.PrimerIPay88Payment?,
                                             error: PrimerIPay88MYSDK.PrimerIPay88Error?) {
        if let payment = payment {
            self.primerIPay88Payment = payment
        }

        if let error = error {
            switch error {
            case .iPay88Error(let description, _):
                let err = PrimerError.paymentFailed(
                    paymentMethodType: PrimerPaymentMethodType.iPay88Card.rawValue,
                    description: "iPay88 payment (transId: \(self.primerIPay88Payment.transId ?? "nil"), refNo: \(self.primerIPay88Payment.refNo ) failed with error '\(description)'",
                    userInfo: ["file": #file,
                               "class": "\(Self.self)",
                               "function": #function,
                               "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                self.didFail?(err)
                self.nullifyCallbacks()
            }

        } else {
            self.didComplete?()
            self.nullifyCallbacks()
        }
    }

    func primerIPay88PaymentCancelled(payment: PrimerIPay88MYSDK.PrimerIPay88Payment?, error: PrimerIPay88MYSDK.PrimerIPay88Error?) {
        self.didCancel?()
        self.nullifyCallbacks()
    }
}
#endif
